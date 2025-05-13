const httpz = @import("httpz");
const Handler = @import("handler.zig");

fn ping(_: *Handler, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .content = "Ponggggggggggg!" }, .{ .emit_null_optional_fields = false });
}
pub fn setup(comptime T: type, server: *httpz.Server(T)) !void {
    const router = try server.router(.{});

    router.get("/", ping, .{});
    return;
}
