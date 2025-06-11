const std = @import("std");

pub const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    STAR,

    // one or two characters tokens.
    SLASH,
    SLASH_SLASH,
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,
    WHITE_SPACE,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF,
};

pub const Token = struct {
    tokenType: TokenType,
    lexeme: []const u8,
    value: ?[]const u8 = null,
    line: usize = 1,

    pub fn init(tokenType: TokenType) Token {
        return .{
            .tokenType = tokenType,
            .lexeme = "",
        };
    }

    pub fn fromTokenTypeLexemeAndValue(tokenType: TokenType, lexeme: []const u8, value: ?[]const u8) Token {
        return .{
            .tokenType = tokenType,
            .lexeme = lexeme,
            .value = value,
        };
    }
};

const Scanner = @This();
allocator: std.mem.Allocator,
source: []const u8,
tokens: std.ArrayList(Token),
start: usize = 0,
current: usize = 0,
line: usize = 1,
hadError: bool = false,

const LexerError = error{
    UnrecognizedToken,
    UnterminatedString,
};

const keywords = std.StaticStringMap(TokenType).initComptime(.{
    .{ "and", .AND },
    .{ "class", .CLASS },
    .{ "else", .ELSE },
    .{ "false", .FALSE },
    .{ "fun", .FUN },
    .{ "for", .FOR },
    .{ "if", .IF },
    .{ "nil", .NIL },
    .{ "or", .OR },
    .{ "print", .PRINT },
    .{ "return", .RETURN },
    .{ "super", .SUPER },
    .{ "this", .THIS },
    .{ "true", .TRUE },
    .{ "var", .VAR },
    .{ "while", .WHILE },
});

pub fn init(allocator: std.mem.Allocator, source: []const u8) Scanner {
    return .{
        .allocator = allocator,
        .source = source,
        .tokens = std.ArrayList(Token).init(allocator),
    };
}

pub fn deinit(self: *Scanner) void {
    for (self.tokens.items) |token| {
        if (token.tokenType == .NUMBER)
            self.allocator.free(token.value.?);
    }
    self.tokens.deinit();
}

fn isAtEnd(self: *Scanner) bool {
    return self.current >= self.source.len;
}

pub fn scanTokens(self: *Scanner) !void {
    while (!self.isAtEnd()) {
        self.start = self.current;
        const token = self.scanToken() catch {
            continue;
        };
        if (token.tokenType == .SLASH_SLASH or token.tokenType == .WHITE_SPACE) continue;
        try self.tokens.append(token);
    }

    try self.tokens.append(.{
        .tokenType = .EOF,
        .lexeme = "",
        .line = self.line,
    });
}

fn advance(self: *Scanner) u8 {
    defer self.current += 1;
    return self.source[self.current];
}

fn match(self: *Scanner, expected: u8) bool {
    if (self.isAtEnd()) return false;
    if (self.source[self.current] != expected) return false;
    self.current += 1;
    return true;
}

fn peek(self: *Scanner) u8 {
    if (self.isAtEnd()) return '\x00';
    return self.source[self.current];
}

fn peekNext(self: *Scanner) u8 {
    if (self.current + 1 >= self.source.len) return '\x00';
    return self.source[self.current + 1];
}

fn scanToken(self: *Scanner) !Token {
    const c = self.advance();
    return switch (c) {
        '(' => Token.fromTokenTypeLexemeAndValue(.LEFT_PAREN, self.source[self.start..self.current], null),
        ')' => Token.fromTokenTypeLexemeAndValue(.RIGHT_PAREN, self.source[self.start..self.current], null),
        '{' => Token.fromTokenTypeLexemeAndValue(.LEFT_BRACE, self.source[self.start..self.current], null),
        '}' => Token.fromTokenTypeLexemeAndValue(.RIGHT_BRACE, self.source[self.start..self.current], null),
        ',' => Token.fromTokenTypeLexemeAndValue(.COMMA, self.source[self.start..self.current], null),
        '.' => Token.fromTokenTypeLexemeAndValue(.DOT, self.source[self.start..self.current], null),
        '-' => Token.fromTokenTypeLexemeAndValue(.MINUS, self.source[self.start..self.current], null),
        '+' => Token.fromTokenTypeLexemeAndValue(.PLUS, self.source[self.start..self.current], null),
        ';' => Token.fromTokenTypeLexemeAndValue(.SEMICOLON, self.source[self.start..self.current], null),
        '*' => Token.fromTokenTypeLexemeAndValue(.STAR, self.source[self.start..self.current], null),
        '=' => {
            return if (self.match('=')) Token.fromTokenTypeLexemeAndValue(.EQUAL_EQUAL, self.source[self.start..self.current], null) else Token.fromTokenTypeLexemeAndValue(.EQUAL, self.source[self.start..self.current], null);
        },
        '!' => {
            return if (self.match('=')) Token.fromTokenTypeLexemeAndValue(.BANG_EQUAL, self.source[self.start..self.current], null) else Token.fromTokenTypeLexemeAndValue(.BANG, self.source[self.start..self.current], null);
        },
        '>' => {
            return if (self.match('=')) Token.fromTokenTypeLexemeAndValue(.GREATER_EQUAL, self.source[self.start..self.current], null) else Token.fromTokenTypeLexemeAndValue(.GREATER, self.source[self.start..self.current], null);
        },
        '<' => {
            return if (self.match('=')) Token.fromTokenTypeLexemeAndValue(.LESS_EQUAL, self.source[self.start..self.current], null) else Token.fromTokenTypeLexemeAndValue(.LESS, self.source[self.start..self.current], null);
        },
        '/' => return if (self.match('/')) blk: {
            while (self.peek() != '\n' and !self.isAtEnd()) {
                _ = self.advance();
            }
            break :blk Token.fromTokenTypeLexemeAndValue(.SLASH_SLASH, self.source[self.start..self.current], null);
        } else Token.fromTokenTypeLexemeAndValue(.SLASH, self.source[self.start..self.current], null),
        ' ', '\r', '\t' => Token.fromTokenTypeLexemeAndValue(.WHITE_SPACE, self.source[self.start..self.current], null),
        '\n' => blk: {
            self.line += 1;
            break :blk Token.fromTokenTypeLexemeAndValue(.WHITE_SPACE, self.source[self.start..self.current], null);
        },
        '"' => {
            const s = try self.string();
            return Token.fromTokenTypeLexemeAndValue(s, self.source[self.start..self.current], self.source[self.start + 1 .. self.current - 1]);
        },
        else => blk: {
            if (std.ascii.isDigit(c)) {
                const t = self.number();
                const raw = self.source[self.start..self.current];
                const v = try std.fmt.parseFloat(f64, raw);
                var buffer: [20]u8 = undefined;
                var output = if (std.ascii.indexOfIgnoreCase(raw, ".")) |_|
                    try std.fmt.bufPrint(&buffer, "{d}", .{v})
                else
                    try std.fmt.bufPrint(&buffer, "{d:.1}", .{v});
                if (std.ascii.indexOfIgnoreCase(output, ".")) |_| {} else {
                    output = try std.fmt.bufPrint(&buffer, "{d:.1}", .{v});
                }
                const value = try self.allocator.dupe(u8, output);
                // std.debug.print("raw: [{s}], v:{} output:{s}\n", .{ raw, v, output });
                break :blk Token.fromTokenTypeLexemeAndValue(t, raw, value);
            } else if (std.ascii.isAlphabetic(c) or c == '_') {
                const t = self.identifier();
                break :blk Token.fromTokenTypeLexemeAndValue(t, self.source[self.start..self.current], null);
            } else {
                const character = [_]u8{c};
                try err(self.line, "Unexpected character: " ++ &character);
                self.hadError = true;
                return LexerError.UnrecognizedToken;
            }
        },
    };
}

fn err(line: usize, message: []const u8) !void {
    try report(line, "", message);
}

fn report(line: usize, where: []const u8, message: []const u8) !void {
    try std.io.getStdErr().writer().print("[line {d}] Error{s}: {s}\n", .{ line, where, message });
}

pub fn print(self: *Scanner) !void {
    for (self.tokens.items) |token| {
        const label = std.enums.tagName(TokenType, token.tokenType);
        try std.io.getStdOut().writer().print("{s} {s} {s}\n", .{ label.?, token.lexeme, if (token.value) |v| v else "null" });
    }
}
fn scanToken_(self: *Scanner) !Token {
    const c = self.advance();
    const token = switch (c) {
        // Single-character tokens.
        '(' => .LEFT_PAREN,
        ')' => .RIGHT_PAREN,
        '{' => .LEFT_BRACE,
        '}' => .RIGHT_BRACE,
        ',' => .COMMA,
        '.' => .DOT,
        '-' => .MINUS,
        '+' => .PLUS,
        ';' => .SEMICOLON,
        '*' => .STAR,

        // one or two characters tokens.
        '!' => if (self.match('=')) .BANG_EQUAL else .BANG,
        '=' => if (self.match('=')) .EQUAL_EQUAL else .EQUAL,
        '>' => if (self.match('=')) .GREATER_EQUAL else .GREATER,
        '<' => if (self.match('=')) .LESS_EQUAL else .LESS,
        '/' => if (self.match('/')) blk: {
            while (self.peek() != '\n' and !self.isAtEnd()) {
                self.advance();
            }
            break :blk .SLASH_SLASH;
        } else .SLASH,
        ' ', '\r', '\t' => .WHITE_SPACE,
        '\n' => blk: {
            self.line += 1;
            break :blk .WHITE_SPACE;
        },
        '"' => self.string(),

        else => blk: {
            if (std.ascii.isDigit(c)) {
                break :blk self.number();
            } else if (std.ascii.isAlphabetic(c) or c == '_') {
                break :blk self.identifier();
            } else {
                break :blk LexerError.UnrecognizedToken;
            }
        },
    };
    return token;
}

fn string(self: *Scanner) !TokenType {
    while (self.peek() != '"' and !self.isAtEnd()) {
        if (self.peek() == '\n') self.line += 1;
        _ = self.advance();
    }

    if (self.isAtEnd()) {
        try err(self.line, "Unterminated string.");
        self.hadError = true;
        return LexerError.UnterminatedString;
    }

    _ = self.advance();
    return .STRING;
}

fn number(self: *Scanner) TokenType {
    while (std.ascii.isDigit(self.peek())) _ = self.advance();
    if (self.peek() == '.' and std.ascii.isDigit(self.peekNext())) {
        _ = self.advance();
        while (std.ascii.isDigit(self.peek())) _ = self.advance();
    }
    return .NUMBER;
}

fn isAlphaNumeric(c: u8) bool {
    return std.ascii.isAlphabetic(c) or c == '_' or std.ascii.isDigit(c);
}

fn identifier(self: *Scanner) TokenType {
    while (isAlphaNumeric(self.peek())) _ = self.advance();
    const ident = self.source[self.start..self.current];
    const tag = if (keywords.get(ident)) |tag| tag else .IDENTIFIER;
    return tag;
}
