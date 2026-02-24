const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    // const arena: std.mem.Allocator = init.arena.allocator();

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const grid: [3][3]u8 = [3][3]u8{
        [3]u8{ 1, 1, 1 },
        [3]u8{ 2, 2, 2 },
        [3]u8{ 3, 3, 3 },
    };
    try print_grid(&grid, stdout_writer);
}

fn print_grid(grid: *const [3][3]u8, writer: *Io.Writer) !void {
    try writer.print(".-.-.-.\n", .{});
    for (grid) |line| {
        try writer.print("|", .{});
        for (line) |byte| {
            try writer.print("{}|", .{byte});
        }
        try writer.print("\n", .{});
        try writer.print(".-.-.-.\n", .{});
    }
    try writer.flush();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
