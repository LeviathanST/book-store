const std = @import("std");
const httpz = @import("httpz");
const zenv = @import("zenv");

const router = @import("router.zig");
const util = @import("util.zig");
const Handler = @import("handler.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var debug_allocator = std.heap.DebugAllocator(.{}).init;

pub fn main() !void {
    const logger = util.Logger.init(std.io.getStdOut().writer());
    const allocator, const is_debug = comptime switch (@import("builtin").mode) {
        .Debug, .ReleaseFast => .{ debug_allocator.allocator(), true },
        else => .{ std.heap.page_allocator, false },
    };
    defer if (is_debug) {
        const leaked = debug_allocator.deinit();
        if (leaked == .leak) {
            std.log.debug("Memory leak is detected", .{});
        }
    };
    const env_reader = try zenv.Reader.init(allocator, .TERM, .{});
    defer env_reader.deinit();
    var handler: Handler = try .init(allocator, env_reader, logger);
    defer handler.deinit();

    const port = try env_reader.readKey(u16, "PORT") orelse 3000;
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
