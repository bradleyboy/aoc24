const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const MAP_TILES_X = 101;
const MAP_TILES_Y = 103;
const SECONDS = 100;

fn printMap(map: []const u64) void {
    const border_row = MAP_TILES_Y / 2;
    const border_col = MAP_TILES_X / 2;

    for (0..map.len, map) |idx, elevation| {
        const row = idx / MAP_TILES_X;
        const col = @rem(idx, MAP_TILES_X);

        if (@rem(idx, MAP_TILES_X) == 0) {
            std.debug.print("\n", .{});
        }

        if (row == border_row) {
            std.debug.print("-", .{});
            continue;
        }

        if (col == border_col) {
            std.debug.print("|", .{});
            continue;
        }

        if (elevation == 0) {
            std.debug.print(".", .{});
        } else {
            std.debug.print("{d}", .{elevation});
        }
    }
    std.debug.print("\n", .{});
}

fn calcMap(map: []const u64) usize {
    const border_row = MAP_TILES_Y / 2;
    const border_col = MAP_TILES_X / 2;

    var nw: usize = 0;
    var ne: usize = 0;
    var sw: usize = 0;
    var se: usize = 0;

    for (0..map.len, map) |idx, value| {
        if (value == 0) {
            continue;
        }

        const row = idx / MAP_TILES_X;
        const col = @rem(idx, MAP_TILES_X);

        if (row == border_row) {
            continue;
        }

        if (col == border_col) {
            continue;
        }

        if (row < border_row and col < border_col) {
            nw += value;
        }

        if (row < border_row and col > border_col) {
            ne += value;
        }

        if (row > border_row and col < border_col) {
            sw += value;
        }

        if (row > border_row and col > border_col) {
            se += value;
        }
    }

    return nw * ne * sw * se;
}

const Bot = struct {
    x: isize,
    y: isize,
    dx: isize,
    dy: isize,

    fn pos2dAtSecond(self: *const Bot, second: isize) usize {
        const total_travel_x = self.dx * second;
        const total_travel_y = self.dy * second;
        const rem_x = @rem(total_travel_x, MAP_TILES_X);
        const rem_y = @rem(total_travel_y, MAP_TILES_Y);

        var new_x = self.x + rem_x;
        var new_y = self.y + rem_y;

        if (new_x < 0) {
            new_x = MAP_TILES_X + new_x;
        }

        if (new_x > MAP_TILES_X - 1) {
            new_x = new_x - MAP_TILES_X;
        }

        if (new_y < 0) {
            new_y = MAP_TILES_Y + new_y;
        }

        if (new_y > MAP_TILES_Y - 1) {
            new_y = new_y - MAP_TILES_Y;
        }

        const new_pos = new_x + (MAP_TILES_X * new_y);

        return @as(usize, @intCast(new_pos));
    }
};

fn botInfoFromLine(line: []u8) !Bot {
    var it = std.mem.splitScalar(u8, line, ' ');

    const pos_part = it.next() orelse return error.InvalidLine;
    var pos_it = std.mem.splitScalar(u8, pos_part[2..], ',');
    const x_s = pos_it.next() orelse return error.InvalidLine;
    const y_s = pos_it.next() orelse return error.InvalidLine;

    const v_part = it.next() orelse return error.InvalidLine;
    var v_it = std.mem.splitScalar(u8, v_part[2..], ',');
    const dx_s = v_it.next() orelse return error.InvalidLine;
    const dy_s = v_it.next() orelse return error.InvalidLine;

    const x = try std.fmt.parseInt(isize, x_s, 10);
    const y = try std.fmt.parseInt(isize, y_s, 10);
    const dx = try std.fmt.parseInt(isize, dx_s, 10);
    const dy = try std.fmt.parseInt(isize, dy_s, 10);

    return Bot{
        .x = x,
        .y = y,
        .dx = dx,
        .dy = dy,
    };
}

pub fn run(alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("input/day14.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var bots = ArrayList(Bot).init(alloc);
    defer bots.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const bot = try botInfoFromLine(line);
        try bots.append(bot);
    }

    for (100..10000) |s| {
        var map = [_]u64{0} ** 10403;
        for (bots.items) |bot| {
            const new_pos = bot.pos2dAtSecond(@as(isize, @intCast(s)));
            map[new_pos] = map[new_pos] + 1;
        }

        const result = calcMap(&map);

        // Very brute force, but eventually this narrowed down to the result for my input.
        if (result < 150000000) {
            printMap(&map);
            std.debug.print("day 14, result at {d}: {d}\n", .{ s, result });
        }
    }
}
