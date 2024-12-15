const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const COST_A = 3;
const COST_B = 1;

fn parseXandYFromLine(line: []u8) !struct { x: usize, y: usize } {
    var it = std.mem.splitBackwardsAny(u8, line, " ");

    const y_part = it.next() orelse return error.InvalidInput;
    const y_s = y_part[2..];
    const y = try std.fmt.parseInt(usize, y_s, 10);

    const x_part = it.next() orelse return error.InvalidInput;
    const x_s = x_part[2..];
    const x = try std.fmt.parseInt(usize, std.mem.trimRight(u8, x_s, ","), 10);

    return .{ .x = x, .y = y };
}

const Claw = struct {
    a_x: usize,
    a_y: usize,
    b_x: usize,
    b_y: usize,
    p_x: usize,
    p_y: usize,
    a_cost: usize,
    b_cost: usize,

    fn fromLines(lines: [][]u8) !Claw {
        if (lines.len != 3) {
            return error.InvalidInput;
        }

        const button_a = try parseXandYFromLine(lines[0]);
        const button_b = try parseXandYFromLine(lines[1]);
        const prize = try parseXandYFromLine(lines[2]);

        return .{
            .a_x = button_a.x,
            .a_y = button_a.y,
            .b_x = button_b.x,
            .b_y = button_b.y,
            .p_x = prize.x,
            .p_y = prize.y,
        };
    }

    fn cheapestWin(self: *Claw) usize {
        var min: usize = 0;
        for (0..100) |a| {
            for (0..100) |b| {
                const x = self.a_x * a + self.b_x * b;
                const y = self.a_y * a + self.b_y * b;

                if (x == self.p_x and y == self.p_y) {
                    const result = a * COST_A + b * COST_B;

                    if (min == 0 or result < min) {
                        min = result;
                    }
                }
            }
        }

        return min;
    }
};

// find max moves allowed for each button based on pixel movement vs target
// find cost of each button, using base cost / pixel movement?
// with cheapest button, try max presses all of that button
// walk backwards adding one press of other button until you hit target
// or, reach all button 2 presses
pub fn run(alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("input/day13.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var line_buffer = ArrayList([]u8).init(alloc);
    defer line_buffer.deinit();

    var total: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            continue;
        }

        const line_copy = try alloc.dupe(u8, line);
        errdefer alloc.free(line_copy);

        try line_buffer.append(line_copy);

        if (line_buffer.items.len == 3) {
            const slice = try line_buffer.toOwnedSlice();
            defer {
                for (slice) |s| alloc.free(s);
                alloc.free(slice);
            }
            var claw = try Claw.fromLines(slice);
            const solve_tokens = claw.cheapestWin();
            total += solve_tokens;
            continue;
        }
    }

    std.debug.print("day 13, tokens: {d}\n", .{total});
}
