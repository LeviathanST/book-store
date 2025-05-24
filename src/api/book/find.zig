const std = @import("std");
const httpz = @import("httpz");
const response = @import("../../response.zig");
const util = @import("../../util.zig");

pub const Book = @import("../../model.zig").Book;
pub const Handler = @import("../../Handler.zig");

pub const Error = Book.FindError;

/// This route using http `query` to specific how books is taken.
/// + **title**: get all books matches the title. *(e.g. ?title=Greate Book)*
/// + **category**: get all bookes in the specified category. *(e.g. ?category=Romantic)*
/// If not specified, it means get all books.
pub fn find(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const allocPrint = std.fmt.allocPrint;
    const query = try req.query();
    if (query.get("title")) |title| {
        const list = try findByTitleInternal(handler, req.arena, title);
        defer list.deinit();
        const msg = try allocPrint(req.arena, "Get all books matches `{s}` in the title!", .{title});
        try response.sendSuccess(res, msg, list.items[0..]);
    } else if (query.get("category")) |category| {
        const list = try Book.findByCategory(handler, req.arena, category);
        defer list.deinit();
        const msg = try allocPrint(req.arena, "Get all books in the {s} category!", .{category});
        try response.sendSuccess(res, msg, list.items[0..]);
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
