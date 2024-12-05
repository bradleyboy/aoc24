const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn findNeighborChar(rows: ArrayList([]const u8), from_row: usize, from_col: usize, c: u8, alloc: Allocator) ![][2]usize {
    var neighbors = std.ArrayList([2]usize).init(alloc);
    defer neighbors.deinit();

    const start_col = if (from_col > 0) from_col - 1 else 0;
    for (start_col..from_col + 2) |col_i| {
        const start_row = if (from_row > 0) from_row - 1 else 0;
        for (start_row..from_row + 2) |row_i| {
            if (col_i == from_col and row_i == from_row) {
                continue;
            }

            if (row_i < 0 or row_i > rows.items.len - 1) {
                continue;
            }

            const row = rows.items[row_i];

            if (row.len == 0 or col_i < 0 or col_i > row.len - 1) {
                continue;
            }

            if (row[col_i] == c) {
                try neighbors.append(.{ row_i, col_i });
            }
        }
    }

    const ret = try neighbors.toOwnedSlice();
    return ret;
}

fn diff(a: usize, b: usize) isize {
    const ai: isize = @intCast(a);
    const bi: isize = @intCast(b);
    return ai - bi;
}

fn matchStemWithDirection(rows: ArrayList([]const u8), start_row: usize, start_col: usize, stem: []const u8, direction: [2]isize) bool {
    for (0.., stem) |i, char| {
        const delta_row = direction[0] * @as(isize, @intCast(i + 1));
        const delta_col = direction[1] * @as(isize, @intCast(i + 1));

        const row_idx = @as(isize, @intCast(start_row)) + delta_row;
        const col_idx = @as(isize, @intCast(start_col)) + delta_col;

        if (row_idx < 0 or col_idx < 0) {
            return false;
        }

        if (row_idx > rows.items.len - 1) {
            return false;
        }

        const row = rows.items[@as(usize, @intCast(row_idx))];

        if (row.len == 0 or col_idx > row.len - 1) {
            return false;
        }

        if (row[@as(usize, @intCast(col_idx))] != char) {
            return false;
        }

        if (char == stem[stem.len - 1]) {
            return true;
        }
    }

    return true;
}

fn part1(alloc: Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(alloc, "input/day4.txt", std.math.maxInt(usize));
    defer alloc.free(input);

    var rows = std.ArrayList([]const u8).init(alloc);
    defer {
        for (rows.items) |row| {
            alloc.free(row);
        }
        rows.deinit();
    }

    var it = std.mem.split(u8, input, "\n");

    while (it.next()) |line| {
        var row = std.ArrayList(u8).init(alloc);
        defer row.deinit();

        for (0.., line) |i, _| {
            try row.append(line[i]);
        }

        try rows.append(try row.toOwnedSlice());
    }

    var total: usize = 0;

    for (0.., rows.items) |i, row| {
        for (0.., row) |j, char| {
            if (char == 'X') {
                const neighbors = try findNeighborChar(rows, i, j, 'M', alloc);
                defer alloc.free(neighbors);

                for (neighbors) |n| {
                    const direction: [2]isize = .{ diff(n[0], i), diff(n[1], j) };
                    const check = matchStemWithDirection(rows, n[0], n[1], "AS", direction);
                    if (check) {
                        total += 1;
                    }
                }
            }
        }
    }

    std.debug.print("day 4, part 1 (total XMAS): {d}\n", .{total});
}

fn part2(alloc: Allocator) !void {
    // iter rows/cols, find A's (ignore first last row)
    // find diagonal neighbors
    // -> are there 2 Ss and 2 Ms
    // -> are the Ss or Ms diagonal to each other? no -> it's an X

    const input = try std.fs.cwd().readFileAlloc(alloc, "input/day4.txt", std.math.maxInt(usize));
    defer alloc.free(input);

    var rows = std.ArrayList([]const u8).init(alloc);
    defer {
        for (rows.items) |row| {
            alloc.free(row);
        }
        rows.deinit();
    }

    var it = std.mem.split(u8, input, "\n");

    while (it.next()) |line| {
        var row = std.ArrayList(u8).init(alloc);
        defer row.deinit();

        for (0.., line) |i, _| {
            try row.append(line[i]);
        }

        try rows.append(try row.toOwnedSlice());
    }

    var total: usize = 0;

    for (1..rows.items.len - 2) |i| {
        const row = rows.items[i];
        for (1..row.len - 1) |j| {
            const char = row[j];
            if (char == 'A') {
                const nw = rows.items[i - 1][j - 1];
                const ne = rows.items[i - 1][j + 1];
                const sw = rows.items[i + 1][j - 1];
                const se = rows.items[i + 1][j + 1];

                var m_count: usize = 0;
                var s_count: usize = 0;

                for ([_]u8{ nw, ne, sw, se }) |c| {
                    if (c == 'M') {
                        m_count += 1;
                    }
                    if (c == 'S') {
                        s_count += 1;
                    }
                }

                // if we have 2 Ss and 2 Ms, and they are not diagonal to each other,
                // we have an X-MAS.
                if (s_count == 2 and m_count == 2 and nw != se and ne != sw) {
                    total += 1;
                }
            }
        }
    }

    std.debug.print("day 4, part 2 (total X-MAS): {d}\n", .{total});
}

pub fn run(alloc: Allocator) !void {
    try part1(alloc);
    try part2(alloc);
}
