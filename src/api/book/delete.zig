const httpz = @import("httpz");
const response = @import("../../response.zig");
const util = @import("../../util.zig");
const Handler = @import("../../Handler.zig");
const Book = @import("../../model.zig").Book;

pub fn deleteByISBN(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const isbn = req.param("isbn") orelse return response.GeneralError.ParamEmpty;
    try util.validator.isbn(h, isbn);
    try Book.deleteByISBN(h, isbn);
    try response.sendSuccess(res, "Delete succesful!", null);
}
