const std = @import("std");
const httpz = @import("httpz");

const router = @import("router.zig");
const util = @import("util.zig");
const Handler = @import("handler.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var debug_allocator = std.heap.DebugAllocator(.{}).init;

pub fn main() !void {
    const logger = util.Logger.init(std.io.getStdOut().writer());
    const allocator, const is_debug = comptime switch (@import("builtin").mode) {
        .Debug, .ReleaseFast => .{ debug_allocator.allocator(), true },
        else => .{ arena.allocator(), false },
    };
    defer if (is_debug) {
        const leaked = debug_allocator.deinit();
        if (leaked == .leak) {
            std.log.debug("Memory leak is detected", .{});
        }
    } else {
        arena.deinit();
    };
    const port_env = try std.process.getEnvVarOwned(allocator, "PORT");
    defer allocator.free(port_env); // Free by debug allocator, do nothing in release mode
    const port = try std.fmt.parseInt(u16, port_env, 10);

    var handler: Handler = try .init(allocator, logger);
    defer handler.deinit();

    var server = try httpz.Server(*Handler).init(allocator, .{
        .address = "0.0.0.0",
        .port = port,
    }, &handler);
    defer {
        server.stop();
        server.deinit();
    }

    try router.setup(*Handler, &server);
    try logger.info("Listening on {d}", .{port});
    try server.listen();
}
