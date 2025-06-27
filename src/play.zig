const std = @import("std");
pub fn main_0() !void {
    std.debug.print("Hola\n", .{});
    const temp = "42.0000";
    const d = try std.fmt.parseFloat(f64, temp);
    std.debug.print("temp: {s} raw:{}, d:{d:.1} d:{d}\n", .{ temp, d, d, d });
}

pub fn main() !void {
    const Person = @import("./person.zig").Person;
    const uzair = Person.init("Uzair Hamed", 23, 'm');
    std.debug.print("{}\n", .{uzair});
}
