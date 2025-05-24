const httpz = @import("httpz");
const util = @import("../../util.zig");
const response = @import("../../response.zig");
pub const Category = @import("../../model.zig").Category;
pub const Handler = @import("../../Handler.zig");

pub fn delete(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const name = req.param("name") orelse return response.GeneralError.ParamEmpty;
    try Category.deleteByName(h, name);
    try response.sendSuccess(res, "Delete successful!", null);
}
