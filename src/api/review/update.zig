const std = @import("std");
const httpz = @import("httpz");
const util = @import("../../util.zig");
const response = @import("../../response.zig");
const Handler = @import("../../Handler.zig");
const Review = @import("../../model.zig").Review;

const UpdateDTO = struct {
    new_content: []const u8,
};

pub fn update(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const data = try util.dto_parser.fromReq(UpdateDTO, req, h);
    const id = req.param("id") orelse return response.GeneralError.ParamEmpty;
    try Review.update(h, try std.fmt.parseInt(i32, id, 10), data.new_content);
    try response.sendSuccess(res, "Update review successful!", null);
}
