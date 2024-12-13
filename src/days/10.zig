const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AuthHashMap = std.AutoHashMap;

pub fn printMap(map: []const u4, line_len: usize) void {
    for (0..map.len, map) |idx, elevation| {
        if (@rem(idx, line_len) == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{d}", .{elevation});
    }
    std.debug.print("\n", .{});
}

fn countUniquePeaks(alloc: Allocator, map: []const u4, line_len: usize, starting_index: usize) !ArrayList(usize) {
    const col = @rem(starting_index, line_len);
    const starting_elevation = map[starting_index];

    if (starting_elevation == 9) {
        var ret = ArrayList(usize).init(alloc);
        try ret.append(starting_index);
        return ret;
    }

    const next_elevation = starting_elevation + 1;
    var visited = AuthHashMap(usize, u1).init(alloc);
    defer visited.deinit();

    if (starting_index >= line_len) {
        const up_index = starting_index - line_len;
        const up_val = map[up_index];

        if (up_val == next_elevation) {
            const visits = try countUniquePeaks(alloc, map, line_len, up_index);
            defer visits.deinit();

            for (visits.items) |v| {
                if (visited.get(v) == null) {
                    try visited.put(v, 1);
                }
            }
        }
    }

    if (starting_index + line_len < map.len) {
        const down_index = starting_index + line_len;
        const down_val = map[down_index];

        if (down_val == next_elevation) {
            const visits = try countUniquePeaks(alloc, map, line_len, down_index);
            defer visits.deinit();

            for (visits.items) |v| {
                if (visited.get(v) == null) {
                    try visited.put(v, 1);
                }
            }
        }
    }

    if (col > 0) {
        const left_index = starting_index - 1;
        const left_val = map[left_index];

        if (left_val == next_elevation) {
            const visits = try countUniquePeaks(alloc, map, line_len, left_index);
            defer visits.deinit();

            for (visits.items) |v| {
                if (visited.get(v) == null) {
                    try visited.put(v, 1);
                }
            }
        }
    }

    if (col < line_len - 1) {
        const right_index = starting_index + 1;
        const right_val = map[right_index];

        if (right_val == next_elevation) {
            const visits = try countUniquePeaks(alloc, map, line_len, right_index);
            defer visits.deinit();

            for (visits.items) |v| {
                if (visited.get(v) == null) {
                    try visited.put(v, 1);
                }
            }
        }
    }

    var ret_list = ArrayList(usize).init(alloc);
    var key_it = visited.keyIterator();

    while (key_it.next()) |visit_idx| {
        try ret_list.append(visit_idx.*);
    }

    return ret_list;
}

pub fn run(alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("input/day10.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var map = ArrayList(u4).init(alloc);
    defer map.deinit();

    var line_len: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line_len == 0) {
            line_len = line.len;
        } else if (line.len != line_len) {
            return error.InvalidInputLineLength;
        }

        for (line) |elevation_s| {
            const elevation = try std.fmt.parseInt(u4, &[1]u8{elevation_s}, 10);
            try map.append(elevation);
        }
    }

    var sum: usize = 0;
    for (0.., map.items) |idx, location| {
        if (location == 0) {
            const result = try countUniquePeaks(alloc, map.items, line_len, idx);
            defer result.deinit();
            sum += result.items.len;
        }
    }

    std.debug.print("day 10, part 1: {d}\n", .{sum});
}
