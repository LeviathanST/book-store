//! JWT module
//!
//! # Features
//! + Generate.
//! + Check `TokenClaims` for all encoded claims.
//! + Verify.
const std = @import("std");
const jwt = @import("zig-jwt");

const Role = @import("../constant.zig").Role;
const Handler = @import("../Handler.zig");
pub const Error = error{ EmptySecret, GenerateFailed, OutOfMemory };
pub const VerifyError = error{InvalidFormat} || jwt.Error;

// TODO: Add refresh token and change name into TokenPair
pub const Token = struct {
    at: []const u8,
};
pub const TokenClaims = struct {
    account_id: i32,
    role: Role,
};

pub fn generate(handler: *Handler, input_claims: TokenClaims, allocator: std.mem.Allocator) !Token {
    const secret = (try handler.env_reader.readKey([]const u8, .{}, "SECRET")).?;
    const s = jwt.SigningMethodHS256.init(allocator);
    const claims: TokenClaims = .{
        .account_id = input_claims.account_id,
        .role = input_claims.role,
    };
    const at = try s.sign(claims, secret);
    return .{ .at = at };
}

pub fn verify(allocator: std.mem.Allocator, at: []const u8, secret: []const u8) !TokenClaims {
    const s = jwt.SigningMethodHS256.init(allocator);
    var token = try s.parse(at, secret);
    const claims = std.json.parseFromValueLeaky(
        TokenClaims,
        allocator,
        try token.getClaims(),
        .{ .ignore_unknown_fields = true },
    ) catch |err| switch (err) {
        std.json.ParseFromValueError.MissingField => return VerifyError.InvalidFormat,
        else => return err,
    };
    return claims;
}
