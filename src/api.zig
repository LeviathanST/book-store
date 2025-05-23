const login = @import("api/auth/login.zig");
pub const loginFn = login.login;
pub const LoginError = login.Error;

const register = @import("api/auth/register.zig");
pub const registerFn = register.register;
pub const RegisterError = register.Error;

const verify = @import("api/auth/verify.zig");
pub const verifyFn = verify.verify;
pub const VerifyError = verify.Error;

// BOOK
const insertBook = @import("api/book/insert.zig");
pub const insertBookFn = insertBook.insert;
pub const InsertBookError = insertBook.Error;

const findBook = @import("api/book/find.zig");
pub const findBooksFn = findBook.find;
pub const findBookByISBNFn = findBook.findByISBN;
pub const FindBookError = findBook.Error;

const updateBook = @import("api/book/update.zig");
pub const updateBookFn = updateBook.updateByISBN;

const deleteBook = @import("api/book/delete.zig");
pub const deleteBookFn = deleteBook.deleteByISBN;
