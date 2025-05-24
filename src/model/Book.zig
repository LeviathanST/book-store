const std = @import("std");
const util = @import("../util.zig");
const Handler = @import("../Handler.zig");

pub const Book = @This();
pub const InsertError = error{DuplicatedISBN};
pub const FindError = error{BookNotFound};

id: i32,
title: []const u8,
description: []const u8,
isbn: []const u8,
author: []const u8,
created_at: i64,
updated_at: i64,

pub fn insert(
    handler: *Handler,
    title: []const u8,
    description: []const u8,
    isbn: []const u8,
    author: []const u8,
) !void {
    const conn = try handler.pool.acquire();
    defer conn.release();

    _ = conn.exec(
        \\ INSERT INTO book (title, description, isbn, author)
        \\ VALUES ($1, $2, $3, $4)
    , .{ title, description, isbn, author }) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) {
                return InsertError.DuplicatedISBN;
            }
        }
        return err;
    };
}

pub fn findAll(h: *Handler, allocator: std.mem.Allocator) !std.ArrayList(Book) {
    const conn = try h.pool.acquire();
    defer conn.release();

    var list = std.ArrayList(Book).init(allocator);
    errdefer list.deinit();

    const rs = conn.queryOpts(
        \\ SELECT * FROM book
    ,
        .{},
        .{ .column_names = true },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    defer rs.deinit();

    while (try rs.next()) |row| {
        const value = try row.to(Book, .{ .map = .name });
        try list.append(value);
    }
    return list;
}

/// Find many matches with a title
pub fn findByTitle(handler: *Handler, allocator: std.mem.Allocator, title: []const u8) !std.ArrayList(Book) {
    const conn = try handler.pool.acquire();
    defer conn.release();

    var list = std.ArrayList(Book).init(allocator);
    errdefer list.deinit();

    const rs = conn.queryOpts(
        \\ SELECT * FROM book WHERE title LIKE '%'|| $1 || '%'
    ,
        .{title},
        .{ .column_names = true },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    defer rs.deinit();

    while (try rs.next()) |row| {
        const value = try row.to(Book, .{ .map = .name });
        try list.append(value);
    }
    return list;
}

pub fn findByISBN(h: *Handler, isbn: []const u8) !Book {
    const conn = try h.pool.acquire();
    defer conn.release();

    var row = conn.row(
        \\ SELECT * FROM book WHERE isbn = $1
    ,
        .{isbn},
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    } orelse return FindError.BookNotFound;
    defer row.deinit() catch unreachable;

    const instance = try row.to(Book, .{});
    return instance;
}

pub fn deleteByISBN(h: *Handler, isbn: []const u8) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    const rows_affected = conn.exec(
        \\ DELETE FROM book WHERE isbn = $1
    ,
        .{isbn},
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
    if (rows_affected == 0) {
        return FindError.BookNotFound;
    }
}

// Update entires row, set the same old value if not updated
pub fn updateByISBN(
    h: *Handler,
    isbn: []const u8,
    new_isbn: ?[]const u8,
    new_title: ?[]const u8,
    new_description: ?[]const u8,
    new_author: ?[]const u8,
) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    const rows_affected = conn.exec(
        \\ UPDATE book
        \\ SET (isbn, title, description, author)
        \\  =  ($1, $2, $3, $4)
        \\ WHERE isbn = $5
    ,
        .{
            new_isbn,
            new_title,
            new_description,
            new_author,
            isbn,
        },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) {
                h.err = "New ISBN already exists";
                return InsertError.DuplicatedISBN;
            }
        }
        return err;
    };

    if (rows_affected == 0) {
        h.err = "Book with specified ISBN not found";
        return FindError.BookNotFound;
    }
}
