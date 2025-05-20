// TODO: Use `https://github.com/rockorager/zeit` instead
const std = @import("std");
const datetime = @import("datetime").datetime;

// "2005-05-17"
pub fn fromSlice(s: []const u8) !datetime.Date {
    var part = std.mem.splitScalar(u8, s, '-');
    const year = std.fmt.parseInt(u32, part.first(), 10) catch return error.InvalidFormat;
    const month = std.fmt.parseInt(u32, part.next().?, 10) catch return error.InvalidFormat;
    const day = std.fmt.parseInt(u32, part.next().?, 10) catch return error.InvalidFormat;
    return datetime.Date.create(year, month, day);
}

test "parse date from slice" {
    const expect = std.testing.expect;
    const date = fromSlice("2015-09-02");
    try expect(date.eql(datetime.Date.create(2015, 9, 2)));
}
