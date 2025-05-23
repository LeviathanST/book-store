//! This module using to parse a data request (body content)
//! into object in Zig
// TODO: make this module be used as a middleware
const std = @import("std");
const httpz = @import("httpz");
const response = @import("../response.zig");
const util = @import("../util.zig");
const Handler = @import("../Handler.zig");

/// This function use `validator.apply()` to make all DTO is validated.
pub fn fromReq(comptime T: type, req: *httpz.Request, handler: *Handler) !T {
    const body = req.body() orelse return response.GeneralError.EmptyBodyContent;
    const data = try std.json.parseFromSliceLeaky(
        T,
        req.arena,
        body,
        .{ .ignore_unknown_fields = true },
    );
    try util.validator.apply(T, data, handler);

    return data;
}
