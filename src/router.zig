const httpz = @import("httpz");
const api = @import("api.zig");
const constant = @import("constant.zig");

const Handler = @import("Handler.zig");

fn ping(_: *Handler, _: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .content = "Ponggggggggggg!" }, .{ .emit_null_optional_fields = false });
}
pub fn setup(comptime T: type, server: *httpz.Server(T)) !void {
    const cors = try server.middleware(httpz.middleware.Cors, .{ .origin = server.handler.global_config.client_url });

    const general_mw = try server.arena.dupe(httpz.Middleware(T), &.{cors});

    var router = try server.router(.{});
    router.middlewares = general_mw;

    router.get("/", ping, .{});
    router.post("/register", api.registerFn, .{});
    router.post("/login", api.loginFn, .{});

    // TODO: This route just for token verification testing,
    // need to remove later
    // TODO: use middleware for each route need auth verification
    router.post("/verify", api.verifyFn, .{
        .data = &Handler.AuthRouteData{ .role = constant.Role.Guest },
        .dispatcher = Handler.authDispatch,
    });
    return;
}
