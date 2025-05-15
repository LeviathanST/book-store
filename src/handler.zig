const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");
const Logger = @import("util.zig").Logger;
const Self = @This();

pool: *pg.Pool,
logger: Logger,

pub fn init(allocator: std.mem.Allocator, logger: Logger) !Self {
    const pool = try pg.Pool.init(allocator, .{
        .auth = .{
            .database = "book-store",
            .username = "root",
            .password = "root",
        },
        .connect = .{
            .host = "db",
            .port = 5432,
        },
    });
    return .{
        .pool = pool,
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
