const std = @import("std");
const httpz = @import("httpz");
const util = @import("../../util.zig");
const response = @import("../../response.zig");
const Handler = @import("../../Handler.zig");

pub const Error = error{ EmptyToken, InvalidFormat };

pub fn verify(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const header = req.header("authorization") orelse return Error.EmptyToken;
    var split = std.mem.splitScalar(u8, header, ' ');
    if (!std.mem.eql(u8, split.first(), "Bearer")) return Error.InvalidFormat;
    try util.token.verify(handler, split.next() orelse return Error.EmptyToken, req.arena);
    try response.sendSuccess(res, "Verify successful!", null);
}
