const httpz = @import("httpz");
const api = @import("api.zig");
const Role = @import("constant.zig").Role;

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
    router.post("/verify", api.verifyFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Guest },
        .dispatcher = Handler.authDispatch,
    });

    router.post("/books", api.insertBookFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    router.put("/books/:isbn", api.updateBookFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    router.delete("/books/:isbn", api.deleteBookFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    router.get("/books/:isbn", api.findBookByISBNFn, .{});
    router.get("/books", api.findBooksFn, .{});

    return;
}
