pub const Report = @This();

var had_error = false;

pub fn resetError() void {
    had_error = false;
}

pub fn hadError() bool {
    return had_error;
}

pub fn out(comptime format: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(format, args) catch |error_out| {
        std.debug.print("Error writing to stdout: {}\n", .{error_out});
    };
}

pub fn outln(comptime format: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(format ++ "\n", args) catch |error_out| {
        std.debug.print("Error writing to stdout: {}\n", .{error_out});
    };
}

pub fn err(comptime format: []const u8, args: anytype) void {
    had_error = true;
    const stderr = std.io.getStdErr().writer();
    stderr.print(format, args) catch |e| {
        std.debug.print("Error writing to stderr: {}\n", .{e});
    };
}

pub fn errln(comptime format: []const u8, args: anytype) void {
    had_error = true;
    const stderr = std.io.getStdErr().writer();
    stderr.print(format ++ "\n", args) catch |e| {
        std.debug.print("Error writing to stderr: {}\n", .{e});
    };
}

pub fn runtimeError(line: usize, comptime fmt: []const u8, args: anytype) void {
    had_error = true;
    const stderr = std.io.getStdErr().writer();
    stderr.print("[line {d}] Error: " ++ fmt ++ "\n", .{line} ++ args) catch |err_runtime| {
        std.debug.print("Error writing to stderr: {}\n", .{err_runtime});
    };
}

const std = @import("std");
