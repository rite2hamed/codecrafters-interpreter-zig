const std = @import("std");

pub const Person = @This();

name: []const u8,
age: u8,
gender: u8,

pub fn init(name: []const u8, age: u8, gender: u8) Person {
    return .{
        .name = name,
        .age = age,
        .gender = gender,
    };
}

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    const gender = if (self.gender == 'm' or self.gender == 'M') "Male" else "Female";
    try writer.print("Name: `{s}`, Gender: {s}, Age: {d} ", .{ self.name, gender, self.age });
}
