const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Spot = enum { open, obstacle };
const Direction = enum { up, down, right, left };

fn rotateDirection(d: Direction) Direction {
    switch (d) {
        .up => return Direction.right,
        .right => return Direction.down,
        .down => return Direction.left,
        .left => return Direction.up,
    }
}

const VisitType = enum { empty, direction };
const Visit = union(VisitType) {
    empty: u8,
    direction: Direction,
};

fn visitIsDirection(visit: Visit, direction: Direction) bool {
    switch (visit) {
        .direction => return visit.direction == direction,
        else => {
            return false;
        },
    }
}

fn solveMapExit(map_slice: []Spot, line_len: u64, start_idx: u64) !u64 {
    var dir: Direction = Direction.up;
    var pos = start_idx;
    var visited = [_]Visit{Visit{ .empty = 0 }} ** 32768;
    visited[start_idx] = Visit{ .direction = Direction.up };

    while (true) {
        switch (dir) {
            .up => {
                if (pos < line_len) {
                    // off map
                    break;
                }

                if (map_slice[pos - line_len] == Spot.open) {
                    pos = pos - line_len;

                    if (visitIsDirection(visited[pos], dir)) {
                        return error.MapInLoop;
                    }

                    visited[pos] = Visit{ .direction = dir };
                } else {
                    dir = rotateDirection(dir);
                }
            },
            .down => {
                if (pos >= map_slice.len - line_len) {
                    // off map
                    break;
                }

                if (map_slice[pos + line_len] == Spot.open) {
                    pos = pos + line_len;

                    if (visitIsDirection(visited[pos], dir)) {
                        return error.MapInLoop;
                    }

                    visited[pos] = Visit{ .direction = dir };
                } else {
                    dir = rotateDirection(dir);
                }
            },
            .right => {
                const row = pos / line_len;
                const row_end = (row * line_len) + line_len - 1;

                if (pos + 1 > row_end) {
                    // off map
                    break;
                }

                if (map_slice[pos + 1] == Spot.open) {
                    pos += 1;

                    if (visitIsDirection(visited[pos], dir)) {
                        return error.MapInLoop;
                    }

                    visited[pos] = Visit{ .direction = dir };
                } else {
                    dir = rotateDirection(dir);
                }
            },
            .left => {
                const row = pos / line_len;
                const row_start = row * line_len;

                if (pos - 1 < row_start) {
                    // off map
                    break;
                }

                if (map_slice[pos - 1] == Spot.open) {
                    pos -= 1;

                    if (visitIsDirection(visited[pos], dir)) {
                        return error.MapInLoop;
                    }

                    visited[pos] = Visit{ .direction = dir };
                } else {
                    dir = rotateDirection(dir);
                }
            },
        }
    }

    var sum: usize = 0;

    for (visited) |v| {
        switch (v) {
            .empty => continue,
            else => {
                sum += 1;
            },
        }
    }

    return sum;
}

pub fn run(alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("input/day6.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var map = ArrayList(Spot).init(alloc);
    defer map.deinit();

    var line_len: usize = 0;
    var start_idx: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line_len == 0) {
            line_len = line.len;
        } else if (line.len != line_len) {
            return error.InvalidInputLineLength;
        }

        for (line) |spot| {
            if (spot == '.') {
                try map.append(Spot.open);
            } else if (spot == '^') {
                start_idx = map.items.len;
                try map.append(Spot.open);
            } else if (spot == '#') {
                try map.append(Spot.obstacle);
            } else {
                return error.InvalidInput;
            }
        }
    }

    const map_slice = try map.toOwnedSlice();
    defer alloc.free(map_slice);

    var loop_spots: usize = 0;

    // takes forever but works, much like myself.
    for (0.., map_slice) |idx, spot| {
        if (spot == Spot.obstacle) {
            continue;
        }

        const original = map_slice[idx];

        map_slice[idx] = Spot.obstacle;

        _ = solveMapExit(map_slice, line_len, start_idx) catch |err| switch (err) {
            error.MapInLoop => loop_spots += 1,
            else => return err,
        };

        map_slice[idx] = original;
    }

    std.debug.print("day 6, loop spots: {d}\n", .{loop_spots});
}
