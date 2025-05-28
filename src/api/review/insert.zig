const httpz = @import("httpz");
const response = @import("../../response.zig");
const util = @import("../../util.zig");
const Handler = @import("../../Handler.zig");
const Review = @import("../../model.zig").Review;

const InsertDTO = struct {
    rate: u3,
    isbn: []const u8,
    content: []const u8,
};

pub fn insert(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const user_id = h.auth_data.?.account_id;
    const data = try util.dto_parser.fromReq(InsertDTO, req, h);
    try Review.insert(h, user_id, data.rate, data.isbn, data.content);
    try response.sendSuccess(res, "Send review successful", null);
}
