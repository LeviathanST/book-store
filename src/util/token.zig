const std = @import("std");
const jwt = @import("zig-jwt");

const Handler = @import("../Handler.zig");
pub const Error = error{ EmptySecret, GenerateFailed, OutOfMemory };
pub const VerifyError = jwt.Error;

// TODO: Add refresh token and change name into TokenPair
pub const Token = struct {
    at: []const u8,
};
pub const TokenClaims = struct {
    account_id: i32,
};

pub fn generate(handler: *Handler, account_id: i32, allocator: std.mem.Allocator) !Token {
    const secret = try handler.env_reader.readKey([]const u8, .{}, "SECRET") orelse return Error.EmptySecret;
    const s = jwt.SigningMethodHS256.init(allocator);
    const claims: TokenClaims = .{
        .account_id = account_id,
    };
    const at = try s.sign(claims, secret);
    return .{ .at = at };
}

pub fn verify(handler: *Handler, at: []const u8, allocator: std.mem.Allocator) !void {
    const secret = try handler.env_reader.readKey([]const u8, .{}, "SECRET") orelse return Error.EmptySecret;
    const s = jwt.SigningMethodHS256.init(allocator);
    var token = try s.parse(at, secret);
    _ = try std.json.parseFromValue(
        TokenClaims,
        allocator,
        try token.getClaims(),
        .{ .ignore_unknown_fields = true },
    );
}
