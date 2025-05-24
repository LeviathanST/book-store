const api = @import("../api.zig");
const Handler = @import("../Handler.zig");
pub const Role = @import("../constant.zig").Role;

const insertCategory = @import("category/insert.zig");
const insertCategoryFn = insertCategory.insert;

const findCategory = @import("category/find.zig");
const findCategories = findCategory.findCategories;
const findACategory = findCategory.findAByName;

const deleteCategory = @import("category/delete.zig");
const deleteCategoryFn = deleteCategory.delete;

const updateCategory = @import("category/update.zig");
const updateCategoryFn = updateCategory.update;

pub const InsertCategoryError = insertCategory.Error;
pub const FindCategoryError = findCategory.Error;

pub fn group(router: *api.AppRouter) void {
    var category_routes = router.group("/categories", .{});
    category_routes.post("/", insertCategoryFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    category_routes.delete("/:name", deleteCategoryFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    category_routes.put("/:name", updateCategoryFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    category_routes.get("/:name", findACategory, .{});
    category_routes.get("/", findCategories, .{});
}
