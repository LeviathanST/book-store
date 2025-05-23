const httpz = @import("httpz");
const response = @import("../../response.zig");
const util = @import("../../util.zig");
const Handler = @import("../../Handler.zig");
const Book = @import("../../model.zig").Book;

const UpdateDTO = struct {
    new_isbn: []const u8,
    new_title: []const u8,
    new_description: []const u8,
    new_author: []const u8,
};

pub fn updateByISBN(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const isbn = req.param("isbn") orelse return response.GeneralError.ParamEmpty;
    try util.validator.isbn(h, isbn);
    const data = try util.dto_parser.fromReq(UpdateDTO, req, h);
    try Book.updateByISBN(
        h,
        isbn,
        data.new_isbn,
        data.new_title,
        data.new_description,
        data.new_author,
    );
    try response.sendSuccess(res, "Update succesful!", null);
}
