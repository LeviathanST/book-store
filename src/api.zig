const login = @import("api/auth/login.zig");
pub const loginFn = login.login;
pub const LoginError = login.Error;

const register = @import("api/auth/register.zig");
pub const registerFn = register.register;
pub const RegisterError = register.Error;

const verify = @import("api/auth/verify.zig");
pub const verifyFn = verify.verify;
pub const VerifyError = verify.Error;
