pub const Interpreter = @This();

had_error: bool = false,

pub fn init() Interpreter {
    return .{};
}

pub fn evaluate(self: *Interpreter, expression: *Expr) Value {
    return switch (expression.*) {
        .literal => |it| self.evaluateLiteralExpr(it),
        .grouping => |it| self.evaluate(it),
        .unary => |it| self.evaluateUnary(it),
        .binary => |it| self.evaluateBinary(it),
    };
}

pub fn evaluateLiteralExpr(_: *Interpreter, literalExpr: LiteralExpr) Value {
    return Value.fromLiteralExpr(literalExpr);
}

pub fn evaluateUnary(self: *Interpreter, unary: UnaryExpr) Value {
    const right = self.evaluate(unary.right);
    return switch (unary.operator.tokenType) {
        .MINUS => switch (right) {
            .number => Value.fromNumber(-right.number),
            else => return self.reportError("Operator must be a number.", .{}),
        },
        .BANG => Value.fromBoolean(switch (right) {
            .number => right.number == 0,
            .string => right.string.len == 0,
            .boolean => !right.boolean,
            .nil => true,
        }),
        else => return self.reportError("Unsupported unary operator: {s}", .{@tagName(unary.operator.tokenType)}),
    };
}

fn reportError(self: *Interpreter, comptime fmt: []const u8, args: anytype) Value {
    self.had_error = true;
    Report.errln(fmt, args);
    return Value.fromNil();
}

pub fn evaluateBinary(self: *Interpreter, binary: BinaryExpr) Value {
    const left = self.evaluate(binary.left);
    const right = self.evaluate(binary.right);
    return switch (binary.operator.tokenType) {
        .STAR => left.mulitply(right) catch |err| switch (err) {
            error.InvalidOperation, error.TypeMismatch => return self.reportError("Operands must be numbers.", .{}),
        },
        .SLASH => left.divide(right) catch |err| switch (err) {
            error.InvalidOperation, error.TypeMismatch => return self.reportError("Operands must be numbers.", .{}),
            error.DivideByZero => return self.reportError("Divide by zero", .{}),
        },
        .MINUS => left.subtract(right) catch |err| switch (err) {
            error.InvalidOperation, error.TypeMismatch => return self.reportError("Operands must be numbers.", .{}),
        },
        .PLUS => left.add(right) catch |err| switch (err) {
            error.InvalidOperation, error.TypeMismatch => return self.reportError("Operands must be numbers.", .{}),
        },
        else => return self.reportError("Unsupported binary operator: {s}", .{@tagName(binary.operator.tokenType)}),
    };
}

const std = @import("std");
const expr = @import("./expr.zig");
const Expr = expr.Expr;
const LiteralExpr = expr.LiteralExpr;
const BinaryExpr = expr.BinaryExpr;
const UnaryExpr = expr.UnaryExpr;
const Value = @import("./value.zig").Value;
const Report = @import("./report.zig");
