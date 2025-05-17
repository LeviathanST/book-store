const std = @import("std");
const httpz = @import("httpz");
const zenv = @import("zenv");
const pg = @import("pg");
const config = @import("config.zig");
const Logger = @import("util.zig").Logger;
const Self = @This();

pool: *pg.Pool,
env_reader: zenv.Reader,
logger: Logger,

pub fn init(allocator: std.mem.Allocator, env_reader: zenv.Reader, logger: Logger) !Self {
    const db_config = try env_reader.readStruct(config.Database);
    const pool = try pg.Pool.init(allocator, .{
        .auth = .{
            .database = db_config.db_database,
            .username = db_config.db_username,
            .password = db_config.db_password,
        },
        .connect = .{
            .host = db_config.db_host,
            .port = db_config.db_port,
        },
    });
    return .{
        .pool = pool,
        .env_reader = env_reader,
        .logger = logger,
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
    var start = std.time.Timer.start() catch @panic("Time error");
    self.logger.err("[{d}us] {s} - {s} 500 Internal Server Error", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    }) catch @panic("Log error");
    self.logger.err("error: {}", .{err}) catch @panic("Log error");
    res.status = 500;
    res.json(.{ .message = "Internal Server Error" }, .{}) catch @panic("Response json error");
}

pub fn dispatch(self: *Self, action: httpz.Action(*Self), req: *httpz.Request, res: *httpz.Response) !void {
    var start = try std.time.Timer.start();
    action(self, req, res) catch |err| {
        if (res.status == 200) { // catch unhandled error
            self.uncaughtError(req, res, err);
            return;
        }
        self.logger.err("[{d}us] {s} - {s} {d}", .{
            start.lap() / 1000,
            @tagName(req.method),
            req.url.path,
            res.status,
        }) catch @panic("Log error");
        return;
    };
    try self.logger.info("[{d}us] {s} - {s} 200 OK", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
}
