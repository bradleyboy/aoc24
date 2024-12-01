const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Input = struct {
    alloc: Allocator,
    sorted_a: []const u64,
    sorted_b: []const u64,
    count_a: AutoHashMap(u64, u64),
    count_b: AutoHashMap(u64, u64),

    pub fn init(path: []const u8, alloc: Allocator) !Input {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();

        var list_one = ArrayList(u64).init(alloc);
        var list_two = ArrayList(u64).init(alloc);
        defer list_one.deinit();
        defer list_two.deinit();

        var map_one = AutoHashMap(u64, u64).init(
            alloc,
        );
        var map_two = AutoHashMap(u64, u64).init(
            alloc,
        );
        errdefer {
            map_one.deinit();
            map_two.deinit();
        }

        var buf: [1024]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var it = std.mem.tokenize(u8, line, " ");
            const one_s = it.next() orelse continue;
            const two_s = it.next() orelse continue;

            const one = try std.fmt.parseInt(u64, one_s, 10);
            const two = try std.fmt.parseInt(u64, two_s, 10);

            try list_one.append(one);
            try list_two.append(two);

            const one_entry = try map_one.getOrPutValue(one, 0);
            one_entry.value_ptr.* += 1;

            const two_entry = try map_two.getOrPutValue(two, 0);
            two_entry.value_ptr.* += 1;
        }

        std.mem.sort(u64, list_one.items, {}, std.sort.asc(u64));
        std.mem.sort(u64, list_two.items, {}, std.sort.asc(u64));

        return .{
            .alloc = alloc,
            .sorted_a = try list_one.toOwnedSlice(),
            .sorted_b = try list_two.toOwnedSlice(),
            .count_a = map_one,
            .count_b = map_two,
        };
    }

    pub fn distance(self: Input) u64 {
        var d: u64 = 0;

        for (self.sorted_a, self.sorted_b) |a_val, b_val| {
            if (b_val > a_val) {
                d += b_val - a_val;
            } else {
                d += a_val - b_val;
            }
        }

        return d;
    }

    pub fn similarity(self: Input) u64 {
        var it = self.count_a.iterator();
        var s: u64 = 0;

        while (it.next()) |item| {
            const a_count = item.value_ptr.*;
            const b_count = self.count_b.get(item.key_ptr.*) orelse 0;

            s += a_count * b_count * item.key_ptr.*;
        }

        return s;
    }

    pub fn deinit(self: *Input) void {
        self.count_a.deinit();
        self.count_b.deinit();
        self.alloc.free(self.sorted_a);
        self.alloc.free(self.sorted_b);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input = try Input.init("day1.txt", allocator);
    defer input.deinit();

    const d = input.distance();
    std.debug.assert(d == 2066446);
    std.debug.print("day 1, part 1 (distance): {d}\n", .{d});

    const s = input.similarity();
    std.debug.assert(s == 24931009);
    std.debug.print("day 1, part 2 (similarity): {d}\n", .{s});
}
