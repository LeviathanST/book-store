const std = @import("std");
const util = @import("../util.zig");
const Handler = @import("../Handler.zig");

const FindBookError = @import("../api.zig").book.FindBookError;
pub const FindError = error{ReviewNotFound};

const Review = @This();

id: i32,
rate: i32,
book_id: i32,
user_id: i32,
content: []const u8,
created_at: i64,
updated_at: i64,

pub fn insert(h: *Handler, user_id: i32, rate: u3, isbn: []const u8, content: []const u8) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    const rows_affected = conn.exec(
        \\ INSERT INTO review (rate, book_id, user_id, content)
        \\ SELECT $1, b.id, $2, $3 
        \\ FROM book b
        \\ WHERE b.isbn = $4
    ,
        .{ rate, user_id, content, isbn },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };

    if (rows_affected == 0) return FindBookError.BookNotFound;
}

pub fn findAllOfBook(h: *Handler, allocator: std.mem.Allocator, isbn: []const u8) !std.ArrayList(Review) {
    const conn = try h.pool.acquire();
    defer conn.release();

    var list = std.ArrayList(Review).init(allocator);
    const rs = try conn.queryOpts(
        \\ SELECT * FROM review
        \\ WHERE book_id = (SELECT id FROM book WHERE isbn = $1)
    , .{isbn}, .{ .column_names = true });
    defer rs.deinit();

    while (try rs.next()) |row| {
        const review = try row.to(Review, .{ .map = .name });
        try list.append(review);
    }
    return list;
}
pub fn delete(h: *Handler, review_id: i32) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    const rows_affected = conn.exec(
        \\ DELETE FROM review
        \\ WHERE id = $1
    ,
        .{review_id},
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };

    if (rows_affected == 0) return FindError.ReviewNotFound;
}
pub fn update(h: *Handler, review_id: i32, new_content: []const u8) !void {
    const conn = try h.pool.acquire();
    defer conn.release();

    const rows_affected = conn.exec(
        \\ UPDATE review
        \\ SET content = $1
        \\ WHERE id = $2
    ,
        .{ new_content, review_id },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    };

    if (rows_affected == 0) return FindError.ReviewNotFound;
}
