const std = @import("std");
const Io = std.Io;

const SIZE: usize = 9;
const SQUARE_SIZE: usize = std.math.sqrt(SIZE);
comptime {
    std.debug.assert(SQUARE_SIZE * SQUARE_SIZE == SIZE);
}

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    // const arena: std.mem.Allocator = init.arena.allocator();

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    // exemple generated from https://sudokusolver.app/
    var grid: [SIZE][SIZE]u8 = load(SIZE, "000030071009020008800004002030100700008000034290000500400000000023761005007008000").?;

    // hardest to bruteforce from https://en.wikipedia.org/wiki/Sudoku_solving_algorithms#Sudoku_brute_force
    // var grid: [SIZE][SIZE]u8 = load(SIZE, "000000000000003085001020000000507000004000100090000000500000073002010000000040009").?;

    // empty grid
    // var grid: [size][size]u8 = std.mem.zeroes([size][size]u8);

    // print the initial grid
    try print_grid(SIZE, &grid, stdout_writer);

    // try to find a solution
    if (!solve_grid(SIZE, &grid)) {
        std.debug.print("sizeo solution found :/\n", .{});
        return;
    }

    // print the solution
    try print_grid(SIZE, &grid, stdout_writer);
}

fn load(comptime size: usize, str: []const u8) ?[size][size]u8 {
    if (str.len != size * size)
        return null;
    var grid: [size][size]u8 = std.mem.zeroes([size][size]u8);
    for (str, 0..str.len) |char, i| {
        if (char < '0' or char > '9')
            return null;
        const x: usize = i % size;
        const y: usize = i / size;
        grid[y][x] = char - '0';
    }
    return grid;
}

fn is_value_possible(comptime size: usize, grid: *const [size][size]u8, x: usize, y: usize, value: u8) bool {
    // row
    for (0..size) |i| {
        if (grid[y][i] == value)
            return false;
    }
    // column
    for (0..size) |i| {
        if (grid[i][x] == value)
            return false;
    }
    // square
    const square_size: usize = std.math.sqrt(size);
    const square_x: usize = (x / square_size) * square_size;
    const square_y: usize = (y / square_size) * square_size;
    for (0..square_size) |dy| {
        for (0..square_size) |dx| {
            if (grid[square_y + dy][square_x + dx] == value)
                return false;
        }
    }
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
            for (0..size) |i| {
                const value: u8 = @intCast(i + 1);
                if (!is_value_possible(size, grid, x, y, value)) {
                    continue;
                }
                grid[y][x] = value;
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
    const square_size: usize = comptime std.math.sqrt(size);

    // compute ascii patterns
    const header: []const u8 = "┏" //
        ++ ("━━━┯" ** (square_size - 1) ++ "━━━┳") // repeat
        ** (square_size - 1) ++ "━━━┯" ** (square_size - 1) ++ "━━━┓\n";
    const middle: []const u8 = "\n┠" // use bold to indicate squares
        ++ ("───┼" ** (square_size - 1) ++ "───╂") // pattern
        ** (square_size - 1) ++ "───┼" ** (square_size - 1) ++ "───┨\n";
    const middle_bold: []const u8 = "\n┣" // use bold to indicate squares
        ++ ("━━━┿" ** (square_size - 1) ++ "━━━╋") // pattern
        ** (square_size - 1) ++ "━━━┿" ** (square_size - 1) ++ "━━━┫\n";
    const footer: []const u8 = "\n┗" //
        ++ ("━━━┷" ** (square_size - 1) ++ "━━━┻") // pattern
        ** (square_size - 1) ++ "━━━┷" ** (square_size - 1) ++ "━━━┛\n";

    try writer.print(header, .{});
    for (0..size) |y| {
        try writer.print("┃", .{});
        for (0..size) |x| {
            if (grid[y][x] == 0) {
                try writer.print("   ", .{});
            } else {
                try writer.print("{: ^3}", .{grid[y][x]});
            }
            if (x % square_size == square_size - 1) {
                try writer.print("┃", .{});
            } else {
                try writer.print("│", .{});
            }
        }
        if (y == size - 1) {
            try writer.print(footer, .{});
            break;
        }
        if (y % square_size == square_size - 1) {
            try writer.print(middle_bold, .{});
        } else {
            try writer.print(middle, .{});
        }
    }
    try writer.flush();
}
