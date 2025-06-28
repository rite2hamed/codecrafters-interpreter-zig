pub const Evaluator = @This();

pub fn evaluate(expr: *Expr) !LiteralExpr {
    switch (expr.*) {
        .literal => |lit| return lit,
        .grouping => |grp| {
            return try evaluate(grp);
        },
        else => {
            return error.NotImplemented;
        },
    }
}

const std = @import("std");
const Expr = @import("./expr.zig").Expr;
const LiteralExpr = @import("./expr.zig").LiteralExpr;
