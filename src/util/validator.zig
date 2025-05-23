//! Using for data request validation.
//! If a validation function fails, it will set error message to `handler.err`.
//!
//! # Features
//! * string validation: ensure data not null, emtpy.
//! * dob: ensure not in the future or present or in the past too long.
//! * isbn: ensure valid format (13-digits, 10-digits)
const std = @import("std");
const util = @import("../util.zig");

const Date = @import("datetime").datetime.Date;
const Handler = @import("../Handler.zig");

pub const Error = error{ StringEmpty, InvalidDob, InvalidType };
pub const ISBNError = error{
    InvalidLength,
    InvalidCharacter,
    InvalidChecksum,
    InvalidFormatISBN,
};

/// This is a validation wrapper where `value` will be validated by field type
pub fn apply(comptime T: type, value: T, h: *Handler) !void {
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (field.type == []const u8 or field.type == []u8) {
            try string(h, field.name, @field(value, field.name));
        }
    }
    if (@hasField(T, "dob")) {
        // TODO: Using Date type directly
        const parsed_date = try util.datetime.fromSlice(@field(value, "dob"));
        try dob(h, parsed_date);
    }
    if (@hasField(T, "isbn")) {
        try isbn(h, @field(value, "isbn"));
    }
}

pub fn string(h: *Handler, comptime name: []const u8, s: []const u8) !void {
    const new = std.mem.trim(u8, s, " ");
    if (new.len == 0) {
        h.err = name ++ " emtpy!";
        return Error.StringEmpty;
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

pub fn isbn(h: *Handler, s: []const u8) !void {
    var digits: [13]u8 = undefined;
    var digit_count: usize = 0;

    for (s, 0..) |char, i| {
        if (char >= '0' and char <= '9') {
            if (digit_count >= 13) {
                h.err = "ISBN must have 10 or 13 digits";
                return ISBNError.InvalidLength;
            }
            digits[digit_count] = char - '0';
            digit_count += 1;
        } else if (char == 'X' and i == s.len - 1 and digit_count == 9) {
            digits[digit_count] = 10;
            digit_count += 1;
        } else if (char == '-' or char == ' ') {
            h.err = "Please remove '-' or ' ' before insert!";
            return ISBNError.InvalidFormatISBN;
        } else {
            h.err = "ISBN contains invalid characters";
            return ISBNError.InvalidCharacter;
        }
    }

    std.log.warn("{d}", .{digit_count});

    if (digit_count == 10) {
        var sum: u32 = 0;
        inline for (digits[0..10], 0..) |digit, i| {
            sum += digit * (10 - @as(u32, @intCast(i)));
        }
        if (sum % 11 != 0) {
            h.err = "Invalid ISBN checksum";
            return ISBNError.InvalidChecksum;
        }
    } else if (digit_count == 13) {
        var sum: u32 = 0;
        inline for (digits[0..13], 0..) |digit, i| {
            sum += digit * (if (i % 2 == 0) 1 else 3);
        }
        if (sum % 10 != 0) {
            h.err = "Invalid ISBN checksum";
            return ISBNError.InvalidChecksum;
        }
    } else {
        h.err = "ISBN must have 10 or 13 digits";
        return ISBNError.InvalidLength;
    }
}
