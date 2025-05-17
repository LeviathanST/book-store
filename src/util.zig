pub const httpz = @import("httpz");
pub const Logger = @import("util/Logger.zig");

pub fn sendError(res: *httpz.Response, status_code: u16, message: []const u8) !void {
    res.status = status_code;
    try res.json(.{
        .message = message,
    }, .{});
}

pub fn sendSuccess(res: *httpz.Response, message: []const u8, data: anytype) !void {
    res.status = 200;
    try res.json(.{
        .message = message,
        .data = data,
    }, .{});
}
