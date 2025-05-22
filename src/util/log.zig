const std = @import("std");

pub fn info(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("\x1b[32m[INFO]: " ++ fmt ++ "\x1b[0m\n", args) catch return;
}
pub fn err(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("\x1b[31m[ERROR]: " ++ fmt ++ "\x1b[0m\n", args) catch return;
}
pub fn warn(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("\x1b[33m[WARN]: " ++ fmt ++ "\x1b[0m\n", args) catch return;
}
