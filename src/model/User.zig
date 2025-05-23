const std = @import("std");
const util = @import("../util.zig");

const Role = @import("../constant.zig").Role;
const Handler = @import("../Handler.zig");
const User = @This();

pub const InsertError = error{DuplicatedEmail};
pub const FindError = error{EmailNotFound};

id: i32,
email: []const u8,
password: []const u8,
first_name: []const u8,
last_name: []const u8,
// TODO: Use Date type instead
dob: []const u8,
role: Role,
created_at: i64,
updated_at: i64,

pub fn deinit(self: *User, allocator: std.mem.Allocator) void {
    inline for (@typeInfo(User).@"struct".fields) |field| {
        const value = @field(self, field.name);
        if (field.type == []const u8 and value.len > 0) {
            allocator.free(value);
        }
    }
    allocator.destroy(self);
}

pub fn insert(
    handler: *Handler,
    email: []const u8,
    password: []const u8,
    first_name: []const u8,
    last_name: []const u8,
    dob: []const u8,
) !void {
    const conn = try handler.pool.acquire();
    defer conn.release();
    _ = conn.exec(
        \\ INSERT INTO "user" (email, password, first_name, last_name, dob)
        \\ VALUES ($1, $2, $3, $4, $5)
    ,
        .{ email, password, first_name, last_name, dob },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
            if (pg_err.isUnique()) {
                return InsertError.DuplicatedEmail;
            }
        }
        return err;
    };
}

pub fn findAByEmail(
    allocator: std.mem.Allocator,
    handler: *Handler,
    email: []const u8,
    comptime props: []const []const u8,
) !User {
    if (props.len <= 0) @compileError("[Find User] Please specify props to query");
    const conn = try handler.pool.acquire();
    defer conn.release();

    var query_builder = std.ArrayList(u8).init(allocator);
    try query_builder.appendSlice("SELECT ");

    const max_len = props.len;
    inline for (props, 0..) |prop, i| {
        try query_builder.appendSlice(prop);
        if (i < max_len - 1) {
            try query_builder.appendSlice(", ");
        }
    }
    try query_builder.appendSlice(" FROM \"user\" WHERE email = $1");

    var row = conn.rowOpts(
        query_builder.items,
        .{email},
        .{ .column_names = true },
    ) catch |err| {
        if (conn.err) |pg_err| {
            util.log.err("{s}", .{pg_err.message});
        }
        return err;
    } orelse return FindError.EmailNotFound;
    defer row.deinit() catch unreachable;

    // SAFETY: assign for each field later
    var user: User = undefined;
    inline for (props) |prop| {
        const @"type" = @FieldType(User, prop);
        if (@"type" == []const u8 or @"type" == u8) {
            const value = try allocator.dupe(u8, row.getCol([]const u8, prop));
            @field(user, prop) = value;
        } else if (@"type" == Role) {
            const raw = row.getCol([]const u8, prop);
            const value = Role.fromSlice(raw);
            @field(user, prop) = value;
        } else {
            @field(user, prop) = row.getCol(@"type", prop);
        }
    }
    return user;
}
