const httpz = @import("httpz");
const response = @import("../../response.zig");
const Handler = @import("../../Handler.zig");
const Review = @import("../../model.zig").Review;

pub const Error = Review.FindError;

pub fn findAllOfBook(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const query = try req.query();
    const isbn = query.get("isbn") orelse return response.GeneralError.QueryEmpty;
    const list = try Review.findAllOfBook(h, req.arena, isbn);
    try response.sendSuccess(res, "Get all reviews of the book!", list.items[0..]);
}
