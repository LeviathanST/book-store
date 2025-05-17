const std = @import("std");
const httpz = @import("httpz");
const util = @import("../util.zig");
const Handler = @import("../handler.zig");

pub const RegisterError = error{EmptyBodyContent};
const RegisterDTO = struct {
    email: []const u8,
    password: []const u8,
};

// TODO:
// pub fn login () !void {
//
// }

pub fn register(handler: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    {
        const body = req.body() orelse {
            try util.sendError(res, 400, "Your body content is empty!");
            return RegisterError.EmptyBodyContent;
        };
        const parsed_body = std.json.parseFromSlice(
            RegisterDTO,
            req.arena,
            body,
            .{ .ignore_unknown_fields = true },
        ) catch |err| switch (err) {
            std.json.ParseFromValueError.MissingField => {
                try util.sendError(res, 400, "Your json data is invalid format!");
                return;
            },
            else => return err,
        };
        try registerInternal(handler, parsed_body.value);
    }
    try util.sendSuccess(res, "Regsiter successful!", .{});
}

fn registerInternal(handler: *Handler, data: RegisterDTO) !void {
    const conn = try handler.pool.acquire();
    defer conn.release();
    _ = conn.exec(
        \\ INSERT INTO "user" (email, password)
        \\ VALUES ($1, $2)
    , .{ data.email, data.password }) catch |err| {
        if (conn.err) |pg_err| {
            std.log.err("{s}", .{pg_err.message});
        }
        return err;
    };
}
