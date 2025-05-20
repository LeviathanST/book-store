const std = @import("std");
const httpz = @import("httpz");
const response = @import("../response.zig");
const Handler = @import("../Handler.zig");
pub fn fromReq(comptime T: type, req: *httpz.Request, handler: *Handler) !T {
    const body = req.body() orelse return response.GeneralError.EmptyBodyContent;
    const parsed_body = try std.json.parseFromSlice(
        T,
        req.arena,
        body,
        .{ .ignore_unknown_fields = true },
    );

    if (!@hasDecl(T, "validate")) {
        @compileError(std.fmt.comptimePrint("Struct {s} not have validate()!", .{@typeName(T)}));
    }
    try parsed_body.value.validate(handler);
    return parsed_body.value;
}
