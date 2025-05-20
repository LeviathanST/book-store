const std = @import("std");
const httpz = @import("httpz");
const api = @import("api.zig");
const util = @import("util.zig");

const TokenVerifyError = util.token.VerifyError;
const ParseFromValueError = std.json.ParseFromValueError;
const ValidationError = util.validator.ValidationError;
const RegisterError = api.RegisterError;
const LoginError = api.LoginError;
const VerifyError = api.VerifyError;

pub const GeneralError = error{EmptyBodyContent};

pub fn sendError(res: *httpz.Response, err: anyerror, message: ?[]const u8) !void {
    switch (err) {
        ParseFromValueError.MissingField => try send(res, 400, "Your request have invalid format content body!", null),
        GeneralError.EmptyBodyContent => try send(res, 400, "Your body content is empty!", null),
        RegisterError.DuplicatedEmail => try send(res, 400, "Email is existed!", null),
        LoginError.EmailNotFound => try send(res, 400, "User not found!", null),
        LoginError.WrongPassword => try send(res, 400, "Wrong password!", null),
        VerifyError.EmptyToken => try send(res, 400, "Your token is empty!", null),
        VerifyError.InvalidFormat => try send(res, 400, "Your token invalid format!", null),
        TokenVerifyError.JWTAlgoInvalid,
        TokenVerifyError.JWTTypeInvalid,
        TokenVerifyError.JWTVerifyFail,
        => try send(res, 400, "Invaid token!", null),
        ValidationError.InvalidDob => try send(res, 400, message.?, null),
        ValidationError.StringEmpty => try send(res, 400, message.?, null),
        else => return err, // Return for uncaughtError()
    }
}

/// A request send by this function always have `status code = 200`
pub fn sendSuccess(res: *httpz.Response, message: []const u8, data: anytype) !void {
    try send(res, 200, message, data);
}

pub fn send(res: *httpz.Response, status: u16, message: []const u8, data: anytype) !void {
    res.status = status;
    try res.json(.{
        .message = message,
        .data = data,
    }, .{ .emit_null_optional_fields = false });
}
