const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// look away i'm hideous
fn rowFromIndex(idx: usize, row_len: usize) usize {
    return @as(usize, @intFromFloat(@floor(@as(f64, @floatFromInt(idx)) / @as(f64, @floatFromInt(row_len)))));
}

pub fn printMap(map: []u8, overrides: []u2, line_len: usize) void {
    for (0..map.len, map) |idx, c| {
        if (@rem(idx, line_len) == 0) {
            std.debug.print("\n", .{});
        }
        if (c == '.' and overrides[idx] == 1) {
            std.debug.print("#", .{});
        } else {
            std.debug.print("{c}", .{c});
        }
    }
    std.debug.print("\n", .{});
}

pub fn run(alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("input/day8.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var map = ArrayList(u8).init(alloc);
    defer map.deinit();

    var line_len: usize = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line_len == 0) {
            line_len = line.len;
        } else if (line.len != line_len) {
            return error.InvalidInputLineLength;
        }

        for (line) |spot| {
            try map.append(spot);
        }
    }

    const map_slice = try map.toOwnedSlice();
    defer alloc.free(map_slice);
    var antinode_map = [_]u2{0} ** 4096;

    for (0.., map_slice) |i, c| {
        if (c == '.') {
            continue;
        }

        const i_row = rowFromIndex(i, line_len);

        for (i + 1..map_slice.len) |j| {
            const match = map_slice[j];
            const j_row = rowFromIndex(j, line_len);

            if (match == c) {
                const distance = j - i;
                const distance_row_span = j_row - i_row;
                antinode_map[i] = 1;
                antinode_map[j] = 1;

                var k = i;
                while (k >= distance and k - distance >= 0) {
                    const antinode_idx = k - distance;
                    const antinode_row = rowFromIndex(antinode_idx, line_len);
                    const k_row = rowFromIndex(k, line_len);

                    if (distance_row_span <= k_row and k_row - distance_row_span == antinode_row) {
                        antinode_map[antinode_idx] = 1;
                    } else {
                        break;
                    }

                    k = antinode_idx;
                }

                var m = j;
                while (m + distance < map_slice.len) {
                    const antinode_idx = m + distance;
                    const antinode_row = rowFromIndex(antinode_idx, line_len);
                    const m_row = rowFromIndex(m, line_len);

                    if (m_row + distance_row_span == antinode_row) {
                        antinode_map[antinode_idx] = 1;
                    } else {
                        break;
                    }

                    m = antinode_idx;
                }
            }
        }
    }

    var sum: usize = 0;
    for (antinode_map) |a| {
        sum += a;
    }

    std.debug.print("day 8, antinodes: {d}\n", .{sum});
}
