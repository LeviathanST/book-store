const std = @import("std");
const httpz = @import("httpz");
const zenv = @import("zenv");

const GlobalConfig = @import("config.zig").GlobalConfig;
const router = @import("router.zig");
const util = @import("util.zig");
const Handler = @import("Handler.zig");

var debug_allocator = std.heap.DebugAllocator(.{}).init;

pub fn main() !void {
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
    const global_config = try env_reader.readStruct(GlobalConfig, .{});
    var handler: Handler = try .init(allocator, env_reader, global_config);
    defer handler.deinit();

    var server = try httpz.Server(*Handler).init(allocator, .{
        .address = "0.0.0.0",
        .port = global_config.port,
    }, &handler);
    defer {
        server.stop();
        server.deinit();
    }

    try router.setup(*Handler, &server);
    util.log.info("Listening on {d}", .{global_config.port});
    try server.listen();
}

test {
    std.testing.refAllDecls(@This());
}
