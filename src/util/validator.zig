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
    const current_date = Date.now();

    if (d.cmp(current_date) != .lt) {
        h.err = "Date of birth must be in the past";
        return error.InvalidDob;
    }

    const years_diff = current_date.year - d.year;
    if (years_diff < 0 or years_diff > 120) {
        h.err = "Date of birth implies an invalid age (must be between 0 and 120 years)";
        return error.InvalidDob;
    }
}
