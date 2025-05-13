const std = @import("std");
const httpz = @import("httpz");
const router = @import("router.zig");
const Logger = @import("logger.zig");
const Handler = @import("handler.zig");

pub fn main() !void {
    const logger = Logger.init(std.io.getStdOut().writer());
    const port = 3000;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var handler: Handler = .{ .logger = logger };
    var server = try httpz.Server(*Handler).init(arena.allocator(), .{ .port = port }, &handler);
    defer {
        server.stop();
        server.deinit();
    }

    try router.setup(*Handler, &server);
    try logger.info("Listening on {d}", .{port});
    try server.listen();
}
