const httpz = @import("httpz");
const util = @import("../../util.zig");
const response = @import("../../response.zig");
const Book = @import("../../model.zig").Book;
const Handler = @import("../../Handler.zig");

pub const Error = Book.InsertError;

const InsertDTO = struct {
    title: []const u8,
    description: []const u8,
    isbn: []const u8,
    author: []const u8,
};

pub fn insert(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const data = try util.dto_parser.fromReq(InsertDTO, req, handler);
    try insertInternal(handler, data);
    try response.sendSuccess(res, "Insert book successful!", null);
}

fn insertInternal(handler: *Handler, data: InsertDTO) !void {
    try Book.insert(handler, data.title, data.description, data.isbn, data.author);
}
