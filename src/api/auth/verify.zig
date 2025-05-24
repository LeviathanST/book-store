const std = @import("std");
const httpz = @import("httpz");
const response = @import("../../response.zig");
const Handler = @import("../../Handler.zig");

pub fn verify(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const msg = try std.fmt.allocPrint(
        req.arena,
        "You are verify with account id - role: {d} - {s}",
        .{
            handler.auth_data.?.account_id,
            @tagName(handler.auth_data.?.role),
        },
    );
    try response.sendSuccess(res, msg, null);
    return;
}
