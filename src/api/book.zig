const api = @import("../api.zig");
const Handler = @import("../Handler.zig");
const Role = @import("../constant.zig").Role;

const insertBook = @import("book/insert.zig");
const insertBookFn = insertBook.insert;

const findBook = @import("book/find.zig");
const findBooksFn = findBook.find;
const findBookByISBNFn = findBook.findByISBN;

const updateBook = @import("book/update.zig");
const updateBookFn = updateBook.updateByISBN;

const deleteBook = @import("book/delete.zig");
const deleteBookFn = deleteBook.deleteByISBN;

pub const FindBookError = findBook.Error;
pub const InsertBookError = insertBook.Error;

pub fn group(router: *api.AppRouter) void {
    var book_routes = router.group("/books", .{});
    book_routes.post("/", insertBookFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    book_routes.put("/:isbn", updateBookFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    book_routes.delete("/:isbn", deleteBookFn, .{
        .data = &Handler.AuthRouteData{ .role = Role.Admin },
        .dispatcher = Handler.authDispatch,
    });
    book_routes.get("/:isbn", findBookByISBNFn, .{});
    book_routes.get("/", findBooksFn, .{});
}
