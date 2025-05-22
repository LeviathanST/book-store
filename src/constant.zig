const std = @import("std");
pub const Role = enum {
    Guest,
    User,
    Admin,

    pub fn fromSlice(s: []const u8) Role {
        if (std.mem.eql(u8, s, "User")) {
            return Role.User;
        } else if (std.mem.eql(u8, s, "Admin")) {
            return Role.Admin;
        } else return Role.Guest;
    }
};
