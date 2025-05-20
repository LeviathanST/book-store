//! This validator use for data request validation.
//! If a validation function fails, it will automatically
//! send an error response.
//!
//! # Features
//! - String validation: ensure data not null, emtpy.
const std = @import("std");

const Date = @import("datetime").datetime.Date;
const Handler = @import("../Handler.zig");

pub const ValidationError = error{ StringEmpty, InvalidDob };

pub fn string(h: *Handler, comptime name: []const u8, s: []const u8) !void {
    const new = std.mem.trim(u8, s, " ");
    if (new.len == 0) {
        h.err = name ++ " emtpy!";
        return ValidationError.StringEmpty;
    }
}

pub fn dob(h: *Handler, d: Date) !void {
    const cmp = d.cmp(Date.now());
    if (cmp != .lt) {
        h.err = "Day of birth cannot be in the feature or present!";
        return ValidationError.InvalidDob;
    }
}
