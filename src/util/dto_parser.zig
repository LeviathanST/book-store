const std = @import("std");
const httpz = @import("httpz");
const response = @import("../response.zig");
const Handler = @import("../Handler.zig");

pub fn fromReq(comptime T: type, req: *httpz.Request, handler: *Handler) !T {
    if (!@hasDecl(T, "validate")) {
        @compileError(std.fmt.comptimePrint("Struct {s} not have validate()!", .{@typeName(T)}));
    }
    const body = req.body() orelse return response.GeneralError.EmptyBodyContent;
    const data = try std.json.parseFromSliceLeaky(
        T,
        req.arena,
        body,
        .{ .ignore_unknown_fields = true },
    );

    try data.validate(handler);
    return data;
}
