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

    // create
    var grid: [4][4]u8 = [4][4]u8{
        [4]u8{ 1, 2, 3, 4 },
        [4]u8{ 2, 3, 4, 1 },
        [4]u8{ 3, 4, 1, 2 },
        [4]u8{ 4, 1, 2, 3 },
    };
    try print_grid(&grid, stdout_writer);

    // test
    if (is_valid(&grid)) {
        std.debug.print("valid!\n", .{});
    } else {
        std.debug.print("invalid.\n", .{});
    }

    // solve
    // solve_grid(&grid);
    // try print_grid(&grid, stdout_writer);
}

fn get_row(grid: *[4][4]u8, y: usize) ?[4]u8 {
    if (y >= grid.len) {
        return null;
    }
    return grid[y];
}
fn get_column(grid: *[4][4]u8, x: usize) ?[4]u8 {
    if (x >= grid.len) {
        return null;
    }
    var column: [4]u8 = [4]u8{ 0, 0, 0, 0 };
    for (0..grid.len) |y| {
        column[y] = grid[y][x];
    }
    return column;
}

fn is_valid(grid: *[4][4]u8) bool {
    for (0..grid.len) |idx| {
        const row = get_row(grid, idx).?;
        const column = get_column(grid, idx).?;

        for (0..grid.len) |value| {
            if (!is_in(&row, value + 1))
                return false;
            if (!is_in(&column, value + 1))
                return false;
        }
    }
    return true;
}

fn is_in(array: *const [4]u8, value: usize) bool {
    for (array) |element| {
        if (element == value)
            return true;
    }
    return false;
}

fn solve_grid(grid: *[4][4]u8) void {
    _ = grid;
}

fn print_grid(grid: *const [4][4]u8, writer: *Io.Writer) !void {
    try writer.print("╭" ++ "───┬" ** (grid.len - 1) ++ "───╮\n", .{});
    for (0..grid.len) |y| {
        try writer.print("│", .{});
        for (0..grid[y].len) |x| {
            try writer.print("{: ^3}│", .{grid[y][x]});
        }
        if (y < grid.len - 1) {
            try writer.print("\n├" ++ "───┼" ** (grid.len - 1) ++ "───┤\n", .{});
        } else {
            try writer.print("\n╰" ++ "───┴" ** (grid.len - 1) ++ "───╯\n", .{});
        }
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
