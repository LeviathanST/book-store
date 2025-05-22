const std = @import("std");
const httpz = @import("httpz");
const api = @import("api.zig");
const util = @import("util.zig");

const ParseFromValueError = std.json.ParseFromValueError;
const AuthError = @import("Handler.zig").AuthError;
const TokenVerifyError = util.token.VerifyError;
const ValidationError = util.validator.ValidationError;
const DatetimeError = util.datetime.Error;
const RegisterError = api.RegisterError;
const LoginError = api.LoginError;

pub const GeneralError = error{EmptyBodyContent};

pub fn sendError(res: *httpz.Response, err: anyerror, message: ?[]const u8) !void {
    switch (err) {
        ParseFromValueError.MissingField => try send(res, 400, "Your request have invalid format content body!", null),
        GeneralError.EmptyBodyContent => try send(res, 400, "Your body content is empty!", null),
        RegisterError.DuplicatedEmail => try send(res, 400, "Email is existed!", null),
        LoginError.EmailNotFound => try send(res, 400, "User not found!", null),
        LoginError.WrongPassword => try send(res, 400, "Wrong password!", null),
        AuthError.EmptyToken => try send(res, 400, "Your token is empty!", null),
        AuthError.InvalidToken => try send(res, 400, "Your token is invalid!", null),
        AuthError.Unauthorized => try send(res, 401, "Not enough permission!", null),
        TokenVerifyError.JWTAlgoInvalid,
        TokenVerifyError.JWTTypeInvalid,
        TokenVerifyError.JWTVerifyFail,
        TokenVerifyError.InvalidFormat,
        => try send(res, 400, "Invaid token!", null),
        DatetimeError.InvalidFormat => try send(res, 400, "Your input date is invalid format!", null),
        DatetimeError.InvalidDate => try send(res, 400, "Your input date is invalid!", null),
        // We need to use `message` field here because we need it more dynamic.
        // (It can return which field is invalid)
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
