pub const Value = union(enum) {
    number: f64,
    string: []const u8,
    boolean: bool,
    nil,

    pub fn format(
        self: Value,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .number => |n| try std.fmt.format(writer, "{d}", .{n}),
            .string => |s| try std.fmt.format(writer, "{s}", .{s}),
            .boolean => |b| try std.fmt.format(writer, "{}", .{b}),
            .nil => try std.fmt.format(writer, "nil", .{}),
        }
    }

    pub fn fromNumber(value: f64) Value {
        return .{ .number = value };
    }

    pub fn fromString(value: []const u8) Value {
        return .{ .string = value };
    }

    pub fn fromBoolean(value: bool) Value {
        return .{ .boolean = value };
    }

    pub fn fromNil() Value {
        return .{ .nil = {} };
    }

    pub fn fromLiteralExpr(literal: LiteralExpr) Value {
        return switch (literal) {
            .boolean => |b| fromBoolean(b),
            .nil => fromNil(),
            .string => |s| fromString(s),
            .number => |n| fromNumber(n),
        };
    }

    pub fn add(self: *Value, other: Value) !Value {
        return switch (self) {
            .number => |left| switch (other) {
                .number => |right| return Value.fromNumber(left + right),
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn subtract(self: *Value, other: Value) !Value {
        return switch (self) {
            .number => |left| switch (other) {
                .number => |right| return Value.fromNumber(left - right),
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn mulitply(self: Value, other: Value) !Value {
        return switch (self) {
            .number => |left| switch (other) {
                .number => |right| return Value.fromNumber(left * right),
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }

    pub fn divide(self: Value, other: Value) !Value {
        return switch (self) {
            .number => |left| switch (other) {
                .number => |right| {
                    if (right == 0) return error.DivideByZero;
                    return Value.fromNumber(left / right);
                },
                else => error.TypeMismatch,
            },
            else => error.InvalidOperation,
        };
    }
};

const std = @import("std");
const LiteralExpr = @import("./expr.zig").LiteralExpr;
