pub const std = @import("std");
pub const httpz = @import("httpz");
pub const response = @import("../../response.zig");
pub const util = @import("../../util.zig");

pub const Book = @import("../../model.zig").Book;
pub const Handler = @import("../../Handler.zig");

pub const Error = Book.FindError;

/// This route using query `title` to find all books matches the title.
/// If not specified, it means get all books.
pub fn find(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const query = try req.query();
    if (query.get("title")) |title| {
        const list = try findByTitleInternal(handler, req.arena, title);
        defer list.deinit();
        try response.sendSuccess(res, "Get all books that match the name!", list.items[0..]);
    } else {
        const list = try Book.findAll(handler, req.arena);
        defer list.deinit();
        try response.sendSuccess(res, "Get all books!", list.items[0..]);
    }
}
fn findByTitleInternal(handler: *Handler, allocator: std.mem.Allocator, title: []const u8) !std.ArrayList(Book) {
    try util.validator.string(handler, "Book title query", title);
    return try Book.findByTitle(handler, allocator, title);
}

pub fn findByISBN(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const isbn = req.param("isbn") orelse return response.GeneralError.ParamEmpty;
    const book = try findByISBNInternal(handler, isbn);
    try response.sendSuccess(res, "Get a book match with ISBN!", book);
}

fn findByISBNInternal(handler: *Handler, isbn: []const u8) !Book {
    try util.validator.isbn(handler, isbn);
    return try Book.findByISBN(handler, isbn);
}
