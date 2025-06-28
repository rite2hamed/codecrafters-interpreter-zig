const std = @import("std");
const Token = @import("./lox.zig").Token;

pub fn Owned(T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        value: *T,

        pub fn init(allocator: std.mem.Allocator, init_value: T) !@This() {
            const ptr = try allocator.create(T);
            errdefer allocator.destroy(ptr);
            ptr.* = init_value;
            return @This(){
                .allocator = allocator,
                .value = ptr,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.allocator.destroy(self.value);
        }

        pub fn get(self: *const @This()) *T {
            return self.value;
        }
    };
}

pub const Expr = union(enum) {
    literal: LiteralExpr,
    grouping: *Expr,
    unary: UnaryExpr,
    binary: BinaryExpr,

    pub fn fromUnary(
        operator: Token,
        right: *Expr,
    ) Expr {
        return .{
            .unary = UnaryExpr{
                .operator = operator,
                .right = right,
            },
        };
    }

    pub fn fromBinary(left: *Expr, op: Token, right: *Expr) Expr {
        return .{
            .binary = BinaryExpr{
                .left = left,
                .operator = op,
                .right = right,
            },
        };
    }

    pub fn fromGrouping(expr: *Expr) Expr {
        return .{
            .grouping = expr,
        };
    }

    pub fn fromBoolean(value: bool) Expr {
        return .{
            .literal = LiteralExpr.fromBoolean(
                value,
            ),
        };
    }

    pub fn fromNil() Expr {
        return .{
            .literal = LiteralExpr.fromNil(),
        };
    }

    pub fn fromString(string: []const u8) Expr {
        return .{
            .literal = LiteralExpr.fromString(
                string,
            ),
        };
    }

    pub fn fromNumber(number: f64) Expr {
        return .{
            .literal = LiteralExpr.fromNumber(
                number,
            ),
        };
    }
};

pub const BinaryExpr = struct {
    left: *Expr,
    operator: Token,
    right: *Expr,
    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try std.fmt.format(writer, "{s}", .{self.operator.lexeme});
    }
};

pub const UnaryExpr = struct {
    operator: Token,
    right: *Expr,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try std.fmt.format(writer, "{s}", .{self.operator.lexeme});
    }
};

pub const LiteralExpr = union(enum) {
    boolean: bool,
    nil: void,
    string: []const u8,
    number: f64,

    pub fn fromBoolean(value: bool) LiteralExpr {
        return .{ .boolean = value };
    }

    pub fn fromNil() LiteralExpr {
        return .{ .nil = {} };
    }

    pub fn fromString(string: []const u8) LiteralExpr {
        return .{ .string = string };
    }

    pub fn fromNumber(number: f64) LiteralExpr {
        return .{ .number = number };
    }

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .boolean => |b| try std.fmt.format(writer, "{}", .{b}),
            .nil => try std.fmt.format(writer, "nil", .{}),
            .string => |s| try std.fmt.format(writer, "{s}", .{s}),
            .number => |n| {
                if (@floor(n) == n) {
                    try std.fmt.format(writer, "{d}.0", .{n});
                } else {
                    try std.fmt.format(writer, "{d}", .{n});
                }
            },
        }
    }

    pub fn eval_format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .boolean => |b| try std.fmt.format(writer, "{}", .{b}),
            .nil => try std.fmt.format(writer, "nil", .{}),
            .string => |s| try std.fmt.format(writer, "{s}", .{s}),
            .number => |n| {
                try std.fmt.format(writer, "{d}", .{n});
            },
        }
    }
};
