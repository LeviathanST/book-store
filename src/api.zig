const httpz = @import("httpz");
const Handler = @import("Handler.zig");
pub const AppRouter = httpz.Router(*Handler, *const fn (*Handler, *httpz.Request, *httpz.Response) anyerror!void);

pub const auth = @import("api/auth.zig");
pub const book = @import("api/book.zig");
pub const category = @import("api/category.zig");
