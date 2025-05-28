const std = @import("std");
const httpz = @import("httpz");
const util = @import("../../util.zig");
const response = @import("../../response.zig");
const Handler = @import("../../Handler.zig");
const Review = @import("../../model.zig").Review;

pub fn delete(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const id = req.param("id") orelse return response.GeneralError.ParamEmpty;
    try Review.delete(h, try std.fmt.parseInt(i32, id, 10));
    try response.sendSuccess(res, "Delete review successful!", null);
}
