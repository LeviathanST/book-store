const httpz = @import("httpz");
const response = @import("../../response.zig");
const util = @import("../../util.zig");
const Handler = @import("../../Handler.zig");
const Book = @import("../../model.zig").Book;

const UpdateDTO = struct {
    isbn: []const u8,
    title: []const u8,
    description: []const u8,
    author: []const u8,
    category: []const u8,
};

pub fn updateByISBN(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const isbn = req.param("isbn") orelse return response.GeneralError.ParamEmpty;
    try util.validator.isbn(h, isbn);
    const data = try util.dto_parser.fromReq(UpdateDTO, req, h);
    try Book.updateByISBN(
        h,
        isbn,
        data.isbn,
        data.title,
        data.description,
        data.author,
        data.category,
    );
    try response.sendSuccess(res, "Update succesful!", null);
}
