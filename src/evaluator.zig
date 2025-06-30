pub const Evaluator = @This();
had_error: bool = false,

pub fn init() Evaluator {
    return .{};
}

pub fn evaluate(expr: *Expr) !LiteralExpr {
    switch (expr.*) {
        .literal => |lit| return lit,
        .grouping => |grp| {
            return try evaluate(grp);
        },
        .unary => |un| {
            const e = try evaluate(un.right);
            if (un.operator.tokenType == .MINUS) {
                const res = try switch (e) {
                    .number => |num| LiteralExpr.fromNumber(-num),
                    else => error.InvalidOperation,
                };
                return res;
            } else {
                return error.NotImplemented;
            }
        },
        else => {
            return error.NotImplemented;
        },
    }
}

const std = @import("std");
const Expr = @import("./expr.zig").Expr;
const LiteralExpr = @import("./expr.zig").LiteralExpr;
