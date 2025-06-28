const std = @import("std");
const Scanner = @import("./lox.zig");
const Parser = @import("./parser.zig").Parser;
const AstPrinter = @import("./ast.zig").AstPrinter;

const TOKENIZE = "tokenize";
const PARSE = "parse";
const EVALUATE = "evaluate";

pub fn main() !void {
    // You can use print statements as follows for debugging, they'll be visible when running tests.
    // std.debug.print("Logs from your program will appear here!\n", .{});

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    const valid_commands = [_][]const u8{ TOKENIZE, PARSE, EVALUATE };
    var found = false;
    for (valid_commands) |valid_command| {
        found = std.mem.eql(u8, command, valid_command);
        if (found) {
            break;
        } else {
            continue;
        }
    }
    if (!found) {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.process.exit(1);
    }

    const file_contents = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, std.math.maxInt(usize));
    defer std.heap.page_allocator.free(file_contents);

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // Uncomment this block to pass the first stage.
    // if (file_contents.len > 0) {
    var scanner = Scanner.init(allocator, file_contents);
    defer scanner.deinit();
    try scanner.scanTokens();

    if (std.mem.eql(u8, command, TOKENIZE)) {
        try scanner.print();
    }

    if (scanner.hadError) {
        std.process.exit(65);
    }
    // } else {
    // try std.io.getStdOut().writer().print("EOF  null\n", .{}); // Placeholder, replace this line when implementing the scanner
    // }

    if (std.mem.eql(u8, command, PARSE)) {
        var parser = Parser.init(allocator, scanner.tokens.items);
        defer parser.deinit();
        const expr = parser.parseExpression() catch |err| {
            std.debug.print("Error during parsing: {s}\n", .{@errorName(err)});
            std.process.exit(65);
        };
        try AstPrinter.write(std.io.getStdOut().writer(), expr);
    }

    if (std.mem.eql(u8, command, EVALUATE)) {
        var parser = Parser.init(allocator, scanner.tokens.items);
        defer parser.deinit();
        const expr = parser.parseExpression() catch |err| {
            std.debug.print("Error during parsing: {s}\n", .{@errorName(err)});
            std.process.exit(65);
        };
        const value = try Evaluator.evaluate(expr);
        std.debug.print("{}", .{value});
    }
}

const Evaluator = @import("./evaluator.zig").Evaluator;
