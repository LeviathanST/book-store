const login = @import("api/auth/login.zig");
pub const loginFn = login.login;
pub const LoginError = login.Error;

const register = @import("api/auth/register.zig");
pub const registerFn = register.register;
pub const RegisterError = register.Error;

const verify = @import("api/auth/verify.zig");
pub const verifyFn = verify.verify;

// BOOK
const insertBook = @import("api/book/insert.zig");
pub const insertBookFn = insertBook.insert;

const findBook = @import("api/book/find.zig");
pub const findBooksFn = findBook.find;
pub const findBookByISBNFn = findBook.findByISBN;

const updateBook = @import("api/book/update.zig");
pub const updateBookFn = updateBook.updateByISBN;

const deleteBook = @import("api/book/delete.zig");
pub const deleteBookFn = deleteBook.deleteByISBN;

pub const FindBookError = findBook.Error;
pub const InsertBookError = insertBook.Error;

// CATEGORY
const insertCategory = @import("api/category/insert.zig");
pub const insertCategoryFn = insertCategory.insert;

const findCategory = @import("api/category/find.zig");
pub const findCategories = findCategory.findCategories;
pub const findACategory = findCategory.findAByName;

const deleteCategory = @import("api/category/delete.zig");
pub const deleteCategoryFn = deleteCategory.delete;

const updateCategory = @import("api/category/update.zig");
pub const updateCategoryFn = updateCategory.update;

pub const InsertCategoryError = insertCategory.Error;
pub const FindCategoryError = findCategory.Error;
