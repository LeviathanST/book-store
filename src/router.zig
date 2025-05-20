const httpz = @import("httpz");
const api = @import("api.zig");

const Handler = @import("Handler.zig");

fn ping(_: *Handler, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .content = "Ponggggggggggg!" }, .{ .emit_null_optional_fields = false });
}
pub fn setup(comptime T: type, server: *httpz.Server(T)) !void {
    const router = try server.router(.{});

    router.get("/", ping, .{});
    router.post("/register", api.registerFn, .{});
    router.post("/login", api.loginFn, .{});

    // TODO: This route just for token verification testing,
    // need to remove later
    // TODO: use middleware for each route need auth verification
    router.post("/verify", api.verifyFn, .{});
    return;
}

pub const RouteData = struct {
    parsed_type: type,
};
