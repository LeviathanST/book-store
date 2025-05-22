const std = @import("std");
const httpz = @import("httpz");
const zenv = @import("zenv");
const pg = @import("pg");
const response = @import("response.zig");
const config = @import("config.zig");
const util = @import("util.zig");

const constant = @import("constant.zig");

const Self = @This();

pool: *pg.Pool,
env_reader: zenv.Reader,
global_config: *const config.GlobalConfig,
/// Modified if non-general error (.e.g `ValidationError`) occurs.
err: ?[]const u8,
/// This using to pass the required internal data for all routing require it
auth_data: ?AuthData,

pub const AuthData = struct {
    account_id: i32,
    role: constant.Role,
};

pub fn init(allocator: std.mem.Allocator, env_reader: zenv.Reader, global_config: *const config.GlobalConfig) !Self {
    const db_config = try env_reader.readStruct(config.Database, .{ .prefix = "DB_" });
    const pool = try pg.Pool.init(allocator, .{
        .auth = .{
            .database = db_config.database,
            .username = db_config.username,
            .password = db_config.password,
        },
        .connect = .{
            .host = db_config.host,
            .port = db_config.port,
        },
    });
    return .{
        .pool = pool,
        .env_reader = env_reader,
        .global_config = global_config,
        .err = null,
        .auth_data = null,
    };
}

pub fn deinit(self: Self) void {
    self.pool.deinit();
}
pub fn notFound(self: *Self, req: *httpz.Request, res: *httpz.Response) !void {
    _ = self;
    var start = try std.time.Timer.start();
    util.log.err("[{d}us] {s} - {s} 404 Not Found", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
    res.status = 404;
}

// TODO: panic should be handled
pub fn uncaughtError(self: *Self, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
    _ = self;
    if (res.status != 200) return;
    var start = std.time.Timer.start() catch @panic("Timer error!");
    util.log.err("[{d}us] {s} - {s} 500 Internal Server Error", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
    util.log.err("error: {}", .{err});
    res.status = 500;
    res.json(.{ .message = "Internal Server Error" }, .{}) catch @panic("Response json error");
}

fn handledError(self: Self, req: *httpz.Request, res: *httpz.Response, err: anyerror) !void {
    try response.sendError(res, err, self.err);
    if (res.status == 200) return;
    var start = try std.time.Timer.start();
    util.log.err("[{d}us] {s} - {s} {d}", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
        res.status,
    });
}

pub fn dispatch(self: *Self, action: httpz.Action(*Self), req: *httpz.Request, res: *httpz.Response) !void {
    var start = try std.time.Timer.start();
    {
        action(self, req, res) catch |err| {
            try self.handledError(req, res, err);
            self.uncaughtError(req, res, err);
            return;
        };
    }
    util.log.info("[{d}us] {s} - {s} 200 OK", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
    self.err = null; // Reset if modified
}

/// This part is used to authenticate
pub const AuthError = error{ EmptyToken, InvalidToken, Unauthorized, EmptyRequiredData };

pub const AuthRouteData = struct {
    /// Needed role
    role: constant.Role,
};

pub fn authDispatch(self: *Self, action: httpz.Action(*Self), req: *httpz.Request, res: *httpz.Response) !void {
    var start = try std.time.Timer.start();
    {
        self.authDispatchInternal(req, res, action) catch |err| {
            try self.handledError(req, res, err);
            self.uncaughtError(req, res, err);
            return;
        };
    }
    util.log.info("[{d}us] {s} - {s} 200 OK", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
    self.err = null; // Reset if modified
    self.auth_data = null; // Reset if modified
}

fn authDispatchInternal(
    self: *Self,
    req: *httpz.Request,
    res: *httpz.Response,
    action: *const fn (
        *Self,
        *httpz.Request,
        *httpz.Response,
    ) anyerror!void,
) !void {
    if (req.route_data) |rd| {
        const data: *const AuthRouteData = @ptrCast(@alignCast(rd));
        const header = req.header("authorization") orelse return AuthError.EmptyToken;
        var split = std.mem.splitScalar(u8, header, ' ');
        if (!std.mem.eql(u8, split.first(), "Bearer")) return AuthError.InvalidToken;
        const claims = try util.token.verify(
            req.arena,
            split.next() orelse return AuthError.EmptyToken,
            self.global_config.secret,
        );
        if (claims.role != data.role) return AuthError.Unauthorized;
        self.auth_data = .{
            .account_id = claims.account_id,
            .role = claims.role,
        };

        try action(self, req, res);
    } else {
        return AuthError.EmptyRequiredData;
    }
}
