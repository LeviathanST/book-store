const insert = @import("review/insert.zig");
const insertFn = insert.insert;

const find = @import("review/find.zig");
const findAllOfBookFn = find.findAllOfBook;

const update = @import("review/update.zig");
const updateFn = update.update;

const delete = @import("review/delete.zig");
const deleteFn = delete.delete;

const Role = @import("../constant.zig").Role;
const Handler = @import("../Handler.zig");
const AppRouter = @import("../api.zig").AppRouter;

pub const FindError = find.Error;

pub fn group(router: *AppRouter) void {
    var review_routes = router.group("reviews", .{});
    review_routes.post("/", insertFn, .{
        .data = &Handler.AuthRouteData{ .roles = &[_]Role{ Role.User, Role.Admin } },
        .dispatcher = Handler.authDispatch,
    });
    review_routes.get("/", findAllOfBookFn, .{});
    review_routes.put("/:id", updateFn, .{});
    review_routes.delete("/:id", deleteFn, .{});
}
