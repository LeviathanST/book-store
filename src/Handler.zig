const std = @import("std");
const httpz = @import("httpz");
const zenv = @import("zenv");
const pg = @import("pg");
const response = @import("response.zig");
const config = @import("config.zig");
const util = @import("util.zig");
const Self = @This();

pool: *pg.Pool,
env_reader: zenv.Reader,
logger: util.Logger,
/// Modified if non-general error (.e.g `ValidationError`) occurs.
err: ?[]const u8,

pub fn init(allocator: std.mem.Allocator, env_reader: zenv.Reader, logger: util.Logger) !Self {
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
        .logger = logger,
        .err = null,
    };
}

pub fn deinit(self: Self) void {
    self.pool.deinit();
}
pub fn notFound(self: *Self, req: *httpz.Request, res: *httpz.Response) !void {
    var start = try std.time.Timer.start();
    try self.logger.err("[{d}us] {s} - {s} 404 Not Found", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
    res.status = 404;
}

// TODO: panic should be handled
pub fn uncaughtError(self: *Self, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
    if (res.status != 200) return;
    var start = std.time.Timer.start() catch @panic("Timer error!");
    self.logger.err("[{d}us] {s} - {s} 500 Internal Server Error", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    }) catch @panic("Log error");
    self.logger.err("error: {}", .{err}) catch @panic("Log error");
    res.status = 500;
    res.json(.{ .message = "Internal Server Error" }, .{}) catch @panic("Response json error");
}

fn handledError(self: Self, req: *httpz.Request, res: *httpz.Response, err: anyerror) !void {
    try response.sendError(res, err, self.err);
    if (res.status == 200) return;
    var start = try std.time.Timer.start();
    self.logger.err("[{d}us] {s} - {s} {d}", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
        res.status,
    }) catch @panic("Log error");
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
    try self.logger.info("[{d}us] {s} - {s} 200 OK", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
    self.err = null; // Reset if modified
}
