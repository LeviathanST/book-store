const std = @import("std");
const util = @import("../util.zig");
const Handler = @import("../Handler.zig");

pub const Category = @This();

pub const InsertError = error{DuplicatedCategory};
pub const FindError = error{CategoryNotFound};

id: i32,
name: []const u8,
description: []const u8,
created_at: i64,
updated_at: i64,

pub fn insert(h: *Handler, name: []const u8, description: []const u8) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    _ = conn.exec(
        \\ INSERT INTO category (name, description)
        \\ VALUES ($1, $2)
    , .{ name, description }) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) {
                return InsertError.DuplicatedCategory;
            }
        }
        return err;
    };
}

pub fn findAll(h: *Handler, allocator: std.mem.Allocator) !std.ArrayList(Category) {
    const conn = try h.pool.acquire();
    defer conn.release();

    var list = std.ArrayList(Category).init(allocator);

    const rs = conn.queryOpts(
        \\ SELECT * FROM category
    ,
        .{},
        .{ .column_names = true },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };

    while (try rs.next()) |row| {
        const value = try row.to(Category, .{ .map = .name });
        try list.append(value);
    }

    return list;
}

pub fn findAByName(h: *Handler, name: []const u8) !Category {
    const conn = try h.pool.acquire();
    defer conn.release();

    const row = conn.rowOpts(
        \\ SELECT * FROM category WHERE name = $1
    ,
        .{name},
        .{ .column_names = true },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    } orelse return FindError.CategoryNotFound;
    return try row.to(Category, .{ .map = .name });
}
/// Return category that matches the `name`.
pub fn findByName(h: *Handler, allocator: std.mem.Allocator, name: []const u8) !std.ArrayList(Category) {
    const conn = try h.pool.acquire();
    defer conn.release();

    var list = std.ArrayList(Category).init(allocator);

    const rs = conn.queryOpts(
        \\ SELECT * FROM category WHERE name LIKE '%' || $1 || '%'
    ,
        .{name},
        .{ .column_names = true },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };

    while (try rs.next()) |row| {
        const value = try row.to(Category, .{ .map = .name });
        try list.append(value);
    }

    return list;
}

pub fn updateByName(h: *Handler, name: []const u8, new_name: []const u8, new_description: []const u8) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    const row_affected = conn.exec(
        \\ UPDATE category
        \\ SET (name, description)
        \\   = ($1, $2) 
        \\ WHERE name = $3 
    , .{ new_name, new_description, name }) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) {
                return InsertError.DuplicatedCategory;
            }
        }
        return err;
    } orelse 0;

    if (row_affected == 0) return FindError.CategoryNotFound;
}

pub fn deleteByName(h: *Handler, name: []const u8) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    const row_affected = conn.exec(
        \\ DELETE FROM category
        \\ WHERE name = $1 
    , .{name}) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };

    if (row_affected == 0) return FindError.CategoryNotFound;
}
