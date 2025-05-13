const std = @import("std");
const httpz = @import("httpz");
const Logger = @import("logger.zig");
const Self = @This();

logger: Logger,

pub fn notFound(self: *Self, req: *httpz.Request, _: *httpz.Response) !void {
    var start = std.time.Timer.start() catch unreachable;
    self.logger.err("[{d}us] {s} - {s} 404 Not Found\n", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    }) catch unreachable;
}

pub fn uncaughtError(self: *Self, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
    var start = std.time.Timer.start() catch unreachable;
    self.logger.err("[{d}us] {s} - {s} {d}\n", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
        res.status,
        err,
    }) catch unreachable;
}

pub fn dispatch(self: *Self, action: httpz.Action(*Self), req: *httpz.Request, res: *httpz.Response) !void {
    var start = try std.time.Timer.start();
    try action(self, req, res);
    try self.logger.info("[{d}us] {s} - {s} 200 OK\n", .{
        start.lap() / 1000,
        @tagName(req.method),
        req.url.path,
    });
}
