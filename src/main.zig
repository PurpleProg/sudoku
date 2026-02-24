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
    const size: usize = 9;
    // assert size is a perfect square
    var grid: [size][size]u8 = std.mem.zeroes([size][size]u8);
    try print_grid(size, &grid, stdout_writer);

    // solve
    if (!solve_grid(size, &grid)) {
        std.debug.print("sizeo solution found :/\n", .{});
        return;
    }
    try print_grid(size, &grid, stdout_writer);

    // test
    if (is_solved(size, &grid)) {
        std.debug.print("valid!\n", .{});
    } else {
        std.debug.print("invalid.\n", .{});
    }
}

fn get_row(comptime size: usize, grid: *const [size][size]u8, y: usize) ?[size]u8 {
    if (y >= size)
        return null;
    return grid[y];
}
fn get_column(comptime size: usize, grid: *const [size][size]u8, x: usize) ?[size]u8 {
    if (x >= size)
        return null;
    var column: [size]u8 = std.mem.zeroes([size]u8);
    for (0..size) |y| {
        column[y] = grid[y][x];
    }
    return column;
}
fn get_square(comptime size: usize, grid: *const [size][size]u8, x: usize, y: usize) ?[size]u8 {
    if (x >= size or y >= size)
        return null;
    const square_size: usize = std.math.sqrt(size);
    const square_x: usize = (x / square_size) * square_size;
    const square_y: usize = (y / square_size) * square_size;

    var square: [size]u8 = std.mem.zeroes([size]u8);
    var i: usize = 0;
    for (0..square_size) |dy| {
        for (0..square_size) |dx| {
            square[i] = grid[square_y + dy][square_x + dx];
            i += 1;
        }
    }
    return square;
}

fn is_full(comptime size: usize, grid: *const [size][size]u8) bool {
    for (0..size) |x| {
        for (0..size) |y| {
            if (grid[y][x] == 0)
                return false;
        }
    }
    return true;
}
fn is_solved(comptime size: usize, grid: *const [size][size]u8) bool {
    // check for any empty cell
    if (!is_full(size, grid))
        return false;
    // check every rows and columns
    for (0..size) |idx| {
        if (contain_double(size, get_row(size, grid, idx).?))
            return false;
        if (contain_double(size, get_column(size, grid, idx).?))
            return false;
    }
    // check every squares
    const square_size: usize = std.math.sqrt(size);
    for (0..square_size) |y| {
        for (0..square_size) |x| {
            const square = get_square(size, grid, x * square_size, y * square_size).?;
            if (contain_double(size, square))
                return false;
        }
    }

    return true;
}

/// skips 0s
fn contain_double(comptime size: usize, array: [size]u8) bool {
    for (0..size - 1) |i| {
        for (i + 1..size) |j| {
            if (array[i] == 0 or array[j] == 0)
                continue;
            // labled loop continue can skip like 3 iteration if array[i] is 0
            // but "premature optimization is the root of all evil"
            // litteraly already O(1) function wtf do i want to optimize
            if (array[i] == array[j])
                return true;
        }
    }
    return false;
}

fn is_placement_possible(comptime size: usize, grid: *const [size][size]u8, x: usize, y: usize) bool {
    if (contain_double(size, get_row(size, grid, y).?))
        return false;
    if (contain_double(size, get_column(size, grid, x).?))
        return false;
    if (contain_double(size, get_square(size, grid, x, y).?))
        return false;
    return true;
}

/// recursive
fn solve_grid(comptime size: usize, grid: *[size][size]u8) bool {
    for (0..size) |y| {
        for (0..size) |x| {
            // skip other that 0
            if (grid[y][x] > 0)
                continue;
            // try to insert something possible, not a double of the lines
            for (0..size) |value| {
                grid[y][x] = @intCast(value + 1);
                if (is_placement_possible(size, grid, x, y))
                    // bubble up valid pos
                    if (solve_grid(size, grid))
                        return true;
            }
            // backtrack
            grid[y][x] = 0;
            return false;
        }
    }
    return true;
}

fn print_grid(comptime size: usize, grid: *const [size][size]u8, writer: *Io.Writer) !void {
    try writer.print("╭" ++ "───┬" ** (size - 1) ++ "───╮\n", .{});
    for (0..size) |y| {
        try writer.print("│", .{});
        for (0..size) |x| {
            if (grid[y][x] == 0) {
                try writer.print("   │", .{});
            } else {
                try writer.print("{: ^3}│", .{grid[y][x]});
            }
        }
        if (y < size - 1) {
            try writer.print("\n├" ++ "───┼" ** (size - 1) ++ "───┤\n", .{});
        } else {
            try writer.print("\n╰" ++ "───┴" ** (size - 1) ++ "───╯\n", .{});
        }
    }
    try writer.flush();
}

// test "simple test" {
//     const gpa = std.testing.allocator;
//     var list: std.ArrayList(i32) = .empty;
//     defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
//     try list.append(gpa, 42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
