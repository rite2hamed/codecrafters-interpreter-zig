const std = @import("std");
const Expr = @import("./expr.zig").Expr;

pub const AstPrinter = struct {
    pub fn write(writer: anytype, expression: *Expr) anyerror!void {
        try switch (expression.*) {
            .literal => |literal| std.fmt.format(writer, "{}", .{literal}),
            .grouping => |grp| {
                var expressions = [_]*Expr{grp};
                try parenthesize(writer, "group", &expressions);
            },
            .unary => |u| {
                var expressions = [_]*Expr{u.right};
                try parenthesize(writer, u.operator.lexeme, &expressions);
            },
            .binary => |bin| {
                var expressions = [_]*Expr{ bin.left, bin.right };
                try parenthesize(writer, bin.operator.lexeme, &expressions);
            },
        };
    }

    pub fn parenthesize(writer: anytype, message: []const u8, expressions: []*Expr) anyerror!void {
        try std.fmt.format(writer, "({s}", .{message});
        for (expressions) |expression| {
            try std.fmt.format(writer, " ", .{});
            try AstPrinter.write(writer, expression);
        }
        try std.fmt.format(writer, ")", .{});
    }
};
