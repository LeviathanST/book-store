const std = @import("std");
const httpz = @import("httpz");

const response = @import("../../response.zig");
const util = @import("../../util.zig");

const Handler = @import("../../Handler.zig");
const User = @import("../../model.zig").User;

pub const Error = error{WrongPassword} || User.FindError;

const LoginDTO = struct {
    email: []const u8,
    password: []const u8,

    pub fn validate(self: LoginDTO, handler: *Handler) !void {
        try util.validator.string(handler, "Email", self.email);
        try util.validator.string(handler, "Password", self.password);
    }
};

pub fn login(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const dto = try util.dto_parser.fromReq(LoginDTO, req, handler);
    const id = try loginInternal(req.arena, handler, dto);
    const token = try util.token.generate(handler, id, req.arena);
    try response.sendSuccess(res, "Login successful!", token);
}

/// Return `account_id` if success
fn loginInternal(allocator: std.mem.Allocator, handler: *Handler, data: LoginDTO) !i32 {
    const user = try User.allocFindAByEmail(allocator, handler, data.email, &.{ "id", "password" });
    defer user.deinit(allocator);
    std.crypto.pwhash.bcrypt.strVerify(
        user.password,
        data.password,
        .{ .silently_truncate_password = false },
    ) catch |err| switch (err) {
        std.crypto.pwhash.KdfError.PasswordVerificationFailed => return Error.WrongPassword,
        else => return err,
    };
    return user.id;
}
