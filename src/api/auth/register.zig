const std = @import("std");
const httpz = @import("httpz");

const util = @import("../../util.zig");
const response = @import("../../response.zig");

const User = @import("../../model.zig").User;
const Handler = @import("../../Handler.zig");

pub const Error = error{EmptyRoundHashing} || User.InsertError;

pub const RegisterDTO = struct {
    email: []const u8,
    password: []const u8,
    first_name: []const u8,
    last_name: []const u8,
    dob: []const u8,
};

pub fn register(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    {
        const dto = try util.dto_parser.fromReq(RegisterDTO, req, handler);
        try registerInternal(handler, dto);
    }
    try response.sendSuccess(res, "Regsiter successful!", .{});
}

fn registerInternal(handler: *Handler, data: RegisterDTO) !void {
    var buf: [std.crypto.pwhash.bcrypt.hash_length * 2]u8 = undefined;
    const hash = try std.crypto.pwhash.bcrypt.strHash(
        data.password,
        .{
            .params = .{
                .rounds_log = handler.global_config.round_hashing,
                .silently_truncate_password = false,
            },
            .encoding = .crypt,
        },
        &buf,
    );
    try User.insert(handler, data.email, hash, data.first_name, data.last_name, data.dob);
}
