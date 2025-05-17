// TODO: remove io error from stdout, use another approach for logging
const std = @import("std");
const Self = @This();

stdout: std.fs.File.Writer,

pub fn init(stdout: std.fs.File.Writer) Self {
    return .{
        .stdout = stdout,
    };
}

pub fn info(self: Self, comptime fmt: []const u8, args: anytype) !void {
    try self.stdout.print("\x1b[32m[INFO]: " ++ fmt ++ "\x1b[0m\n", args);
}
pub fn err(self: Self, comptime fmt: []const u8, args: anytype) !void {
    try self.stdout.print("\x1b[31m[ERROR]: " ++ fmt ++ "\x1b[0m\n", args);
}
pub fn warn(self: Self, comptime fmt: []const u8, args: anytype) !void {
    try self.stdout.print("\x1b[33m[WARN]: " ++ fmt ++ "\x1b[0m\n", args);
}
