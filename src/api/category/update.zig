const httpz = @import("httpz");
const util = @import("../../util.zig");
const response = @import("../../response.zig");
pub const Category = @import("../../model.zig").Category;
pub const Handler = @import("../../Handler.zig");

const UpdateDTO = struct {
    name: []const u8,
    description: []const u8,
};

pub fn update(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const name = req.param("name") orelse return response.GeneralError.ParamEmpty;
    const data = try util.dto_parser.fromReq(UpdateDTO, req, h);
    try Category.updateByName(h, name, data.name, data.description);
    try response.sendSuccess(res, "Update successful!", null);
}
