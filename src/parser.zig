const std = @import("std");
const Token = @import("./lox.zig").Token;
const TokenType = @import("./lox.zig").TokenType;
const Expr = @import("./expr.zig").Expr;
const OwnedExpr = @import("./expr.zig").Owned(Expr);

tokens: []const Token,
allocator: std.mem.Allocator,
current: usize = 0,
expressions: std.ArrayList(OwnedExpr),
hadErrors: bool = false,

pub const Parser = @This();

pub const ParserError = error{ UnexpectedToken, OutOfMemory, LiteralToStringParse };

pub fn init(
    allocator: std.mem.Allocator,
    tokens: []const Token,
) Parser {
    return .{
        .allocator = allocator,
        .tokens = tokens,
        .expressions = std.ArrayList(OwnedExpr).init(allocator),
    };
}

pub fn deinit(self: *Parser) void {
    //clean up allocated owned expressions
    // std.debug.print("gonna clean up: {d} expressions\n", .{self.expressions.items.len});
    for (self.expressions.items) |*item| {
        item.deinit();
    }
    self.expressions.deinit();
}

pub fn parseExpression(self: *Parser) ParserError!*Expr {
    return try self.expression();
}

fn expression(self: *Parser) ParserError!*Expr {
    return try self.equality();
}

fn equality(self: *Parser) ParserError!*Expr {
    var expr = try self.comparison();
    while (self.match(&[_]TokenType{ .BANG_EQUAL, .EQUAL_EQUAL })) {
        const operator = self.previous();
        const right = try self.comparison();
        expr = return try self.createExpression(Expr.fromBinary(expr, operator, right));
    }
    return expr;
}

fn comparison(self: *Parser) ParserError!*Expr {
    var expr = try self.term();
    while (self.match(&[_]TokenType{ .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL })) {
        const operator = self.previous();
        const right = try self.term();
        expr = try self.createExpression(Expr.fromBinary(expr, operator, right));
    }
    return expr;
}

fn term(self: *Parser) ParserError!*Expr {
    var expr = try self.factor();
    while (self.match(&[_]TokenType{ .MINUS, .PLUS })) {
        const operator = self.previous();
        const right = try self.factor();
        expr = try self.createExpression(Expr.fromBinary(expr, operator, right));
    }
    return expr;
}

fn factor(self: *Parser) ParserError!*Expr {
    var expr = try self.unary();
    while (self.match(&[_]TokenType{ .SLASH, .STAR })) {
        const operator = self.previous();
        const right = try self.unary();
        expr = try self.createExpression(Expr.fromBinary(expr, operator, right));
    }
    return expr;
}

fn unary(self: *Parser) ParserError!*Expr {
    if (self.match(&[_]TokenType{ .BANG, .MINUS })) {
        const operator = self.previous();
        const right = try self.unary();
        return try self.createExpression(Expr.fromUnary(operator, right));
    }
    return try self.primary();
}

fn primary(self: *Parser) ParserError!*Expr {
    if (self.match(&[_]TokenType{.FALSE})) return try self.createExpression(Expr.fromBoolean(false));
    if (self.match(&[_]TokenType{.TRUE})) return try self.createExpression(Expr.fromBoolean(true));
    if (self.match(&[_]TokenType{.NIL})) return try self.createExpression(Expr.fromNil());
    //todo convert to a number
    if (self.match(&[_]TokenType{.NUMBER})) return try self.createExpression(Expr.fromNumber(0.0));
    if (self.match(&[_]TokenType{.STRING})) return try self.createExpression(Expr.fromString(self.previous().lexeme));

    if (self.match(&[_]TokenType{.LEFT_PAREN})) {
        const expr = try self.expression();
        _ = try self.consume(.RIGHT_PAREN, "Expect ')' after expression.");
        return try self.createExpression(Expr.fromGrouping(expr));
    }

    const writer = std.io.getStdErr().writer();
    const reportToken = self.peek();
    std.fmt.format(writer, "[line {d}] Error at '{s}': Expect expression\n", .{ reportToken.line, reportToken.lexeme }) catch {};

    return ParserError.UnexpectedToken;
}

fn createExpression(self: *Parser, value: Expr) ParserError!*Expr {
    const expr = try OwnedExpr.init(self.allocator, value);
    try self.expressions.append(expr);
    return expr.get();
}

fn consume(self: *Parser, tt: TokenType, message: []const u8) ParserError!Token {
    if (self.check(tt)) return self.advance();
    const writer = std.io.getStdErr().writer();
    std.fmt.format(writer, "[line {d}] Error: {s}", .{ self.peek().line, message }) catch {};

    return ParserError.UnexpectedToken;
}

fn match(self: *Parser, tokenTypes: []const TokenType) bool {
    for (tokenTypes) |tt| {
        if (self.check(tt)) {
            _ = self.advance();
            return true;
        }
    }
    return false;
}

fn check(self: *Parser, tokenType: TokenType) bool {
    if (self.isAtEnd()) return false;
    return self.peek().tokenType == tokenType;
}

fn advance(self: *Parser) Token {
    if (!self.isAtEnd()) self.current += 1;
    return self.previous();
}

fn isAtEnd(self: *Parser) bool {
    return self.peek().tokenType == .EOF;
}

fn peek(self: *Parser) Token {
    return self.tokens[self.current];
}

fn previous(self: *Parser) Token {
    return self.tokens[self.current - 1];
}
