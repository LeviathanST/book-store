const httpz = @import("httpz");
const response = @import("../../response.zig");
const Category = @import("../../model.zig").Category;
const Handler = @import("../../Handler.zig");

pub const Error = Category.FindError;

/// This route using query `name` to find all categories matches the name.
/// If not specified, it means get all categories.
pub fn findCategories(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const query = try req.query();
    if (query.get("name")) |name| {
        const list = try Category.findByName(h, req.arena, name);
        try response.sendSuccess(res, "Get categories that matches with the name!", list.items[0..]);
    } else {
        const list = try Category.findAll(h, req.arena);
        try response.sendSuccess(res, "Get all categories!", list.items[0..]);
    }
}

pub fn findAByName(h: *Handler, req: *httpz.Request, res: *httpz.Response) !void {
    const name = req.param("name") orelse return response.GeneralError.ParamEmpty;
    const category = try Category.findAByName(h, name);
    try response.sendSuccess(res, "Get categories that matches with the name!", category);
}
