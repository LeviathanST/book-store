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
pub fn notFound(self: *Self, req: *httpz.Request, _: *httpz.Response) !void {
    var start = std.time.Timer.start() catch unreachable;
    self.logger.err("[{d}us] {s} - {s} 404 Not Found", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    }) catch unreachable;
}

pub fn uncaughtError(self: *Self, req: *httpz.Request, res: *httpz.Response, _: anyerror) void {
    var start = std.time.Timer.start() catch unreachable;
    inline for (@typeInfo(std.http.Status).@"enum".fields) |status| {
        if (status.value == res.status) {
            self.logger.err("[{d}us] {s} - {s} {d} {s}", .{
                start.lap() / 1000,
                @tagName(req.method),
                req.url.path,
                res.status,
                status.name,
            }) catch unreachable;
        } else {
            self.logger.err("[{d}us] {s} - {s} {d} {s}", .{
                start.lap() / 1000,
                @tagName(req.method),
                req.url.path,
                res.status,
                "UNKNOW ERROR",
            }) catch unreachable;
        }
    }
}

pub fn dispatch(self: *Self, action: httpz.Action(*Self), req: *httpz.Request, res: *httpz.Response) !void {
    var start = try std.time.Timer.start();
    try action(self, req, res);
    try self.logger.info("[{d}us] {s} - {s} 200 OK", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
}
