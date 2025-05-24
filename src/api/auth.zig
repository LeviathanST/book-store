const login = @import("auth/login.zig");
pub const loginFn = login.login;

const register = @import("auth/register.zig");
pub const registerFn = register.register;

const verify = @import("auth/verify.zig");
pub const verifyFn = verify.verify;

pub const LoginError = login.Error;
pub const RegisterError = register.Error;
