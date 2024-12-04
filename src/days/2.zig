const std = @import("std");
const Allocator = std.mem.Allocator;

fn diff(a: u64, b: u64) u64 {
    if (a > b) {
        return a - b;
    }

    return b - a;
}

fn validLevelsLineWithTolerance(levels_in: []const u64, alloc: Allocator) !bool {
    const full = try validLevelsLine(levels_in);

    if (full) {
        return true;
    }

    for (0..levels_in.len) |skip| {
        var levels = std.ArrayList(u64).init(alloc);
        defer levels.deinit();

        for (0.., levels_in) |idx, level| {
            if (idx != skip) {
                try levels.append(level);
            }
        }

        const slice = try levels.toOwnedSlice();
        defer alloc.free(slice);
        const t = try validLevelsLine(slice);

        if (t) {
            return true;
        }
    }

    return false;
}

fn validLevelsLine(levels_in: []const u64) !bool {
    const is_increasing = levels_in[0] < levels_in[1];

    for (0..levels_in.len - 1) |i| {
        const level = levels_in[i];
        const next = levels_in[i + 1];
        const delta = diff(level, next);

        if (delta < 1 or delta > 3) {
            return false;
        }

        const is_increasing_pair = level < next;

        if (is_increasing != is_increasing_pair) {
            return false;
        }
    }

    return true;
}

fn lineToSlice(line: []const u8, alloc: Allocator) ![]const u64 {
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    var slice = std.ArrayList(u64).init(alloc);

    while (it.next()) |level_s| {
        const level = try std.fmt.parseInt(u64, level_s, 10);
        try slice.append(level);
    }

    return slice.toOwnedSlice();
}

pub fn run(alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("input/day2.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var safe_reports: u64 = 0;

    // Read input line by line
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const slice = try lineToSlice(line, alloc);
        defer alloc.free(slice);

        const result = try validLevelsLineWithTolerance(slice, alloc);

        if (result) {
            safe_reports += 1;
        }
    }

    std.debug.print("day 2, safe reports: {d}\n", .{safe_reports});
}
