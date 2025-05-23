//! This module is temporarily containing some
//! to parse another type (usually a slice)
//! into `Date` or `Datetime`
//!
//! # Features
//! * convert slice into `Date` with format `"YYYY-MM-DD"`
// TODO: Use `https://github.com/rockorager/zeit` instead
const std = @import("std");
const datetime = @import("datetime").datetime;

pub const Error = error{ InvalidFormatDate, InvalidDate };

// "2005-05-17"
pub fn fromSlice(s: []const u8) Error!datetime.Date {
    var part = std.mem.splitScalar(u8, s, '-');
    const year = std.fmt.parseInt(u32, part.first(), 10) catch return Error.InvalidFormatDate;
    const month = std.fmt.parseInt(u32, part.next() orelse return Error.InvalidFormatDate, 10) catch return Error.InvalidFormatDate;
    const day = std.fmt.parseInt(u32, part.next() orelse return Error.InvalidFormatDate, 10) catch return Error.InvalidFormatDate;
    return @errorCast(datetime.Date.create(year, month, day));
}

test "parse date from slice" {
    const expect = std.testing.expect;
    const date = fromSlice("2015-09-02");
    try expect(date.eql(datetime.Date.create(2015, 9, 2)));
}
