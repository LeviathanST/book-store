const httpz = @import("httpz");
const util = @import("../../util.zig");
const response = @import("../../response.zig");
pub const Category = @import("../../model.zig").Category;
pub const Handler = @import("../../Handler.zig");

pub const Error = Category.InsertError;

const InsertDTO = struct {
    name: []const u8,
    description: []const u8,
};

pub fn insert(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const data = try util.dto_parser.fromReq(InsertDTO, req, h);
    try Category.insert(h, data.name, data.description);
    try response.sendSuccess(res, "Insert successful!", null);
}
