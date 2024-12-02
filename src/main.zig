const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

// Our Inout struct parses the initial input into the different
// data structures we need to answer parts 1 and 2.
const Input = struct {
    alloc: Allocator,

    // sorted_a / b hold the sorted versions of the two input lists
    sorted_a: []const u64,
    sorted_b: []const u64,

    // count_a / count_b are maps where the keys are the list values,
    // and the values are the number of times each value occurs in the list.
    count_a: AutoHashMap(u64, u64),
    count_b: AutoHashMap(u64, u64),

    pub fn init(reader: std.io.AnyReader, alloc: Allocator) !Input {
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

        // Only clean these up on error, as they are used externally.
        // we clean them up in deinit()
        errdefer {
            map_one.deinit();
            map_two.deinit();
        }

        var buf_reader = std.io.bufferedReader(reader);
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        // Read input line by line
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var it = std.mem.tokenize(u8, line, " ");
            const one_s = it.next() orelse continue;
            const two_s = it.next() orelse continue;

            const one = try std.fmt.parseInt(u64, one_s, 10);
            const two = try std.fmt.parseInt(u64, two_s, 10);

            try list_one.append(one);
            try list_two.append(two);

            // For each entry, add it to the hashmap, initializing
            // the count with 0 if we haven't seen it yet.
            //
            // Not sure if mutating by dereferencing is the best
            // thing to do /shrug
            const one_entry = try map_one.getOrPutValue(one, 0);
            one_entry.value_ptr.* += 1;

            const two_entry = try map_two.getOrPutValue(two, 0);
            two_entry.value_ptr.* += 1;
        }

        // Now that we have build the lists, sort them in place.
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

    pub fn deinit(self: *Input) void {
        self.count_a.deinit();
        self.count_b.deinit();
        self.alloc.free(self.sorted_a);
        self.alloc.free(self.sorted_b);
    }
};

fn distance(a: []const u64, b: []const u64) u64 {
    std.debug.assert(a.len == b.len);

    var d: u64 = 0;

    for (a, b) |a_val, b_val| {
        // using @abs() is tricky here since we are already
        // dealing with u64, so casting to i64 is fraught.
        // So we do things manually, which is fine!
        if (b_val > a_val) {
            d += b_val - a_val;
        } else {
            d += a_val - b_val;
        }
    }

    return d;
}

fn similarity(a: AutoHashMap(u64, u64), b: AutoHashMap(u64, u64)) u64 {
    var it = a.iterator();
    var s: u64 = 0;

    while (it.next()) |item| {
        const a_count = item.value_ptr.*;
        const b_count = b.get(item.key_ptr.*) orelse 0;

        // Since our input parsing groups both list counts, we
        // multiply the value times its count in both lists to
        // satisfy the requirements of the question in part 2.
        s += a_count * b_count * item.key_ptr.*;
    }

    return s;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("day1.txt", .{});
    defer file.close();

    var input = try Input.init(file.reader().any(), allocator);
    defer input.deinit();

    const d = distance(input.sorted_a, input.sorted_b);
    std.debug.print("day 1, part 1 (distance): {d}\n", .{d});

    const s = similarity(input.count_a, input.count_b);
    std.debug.print("day 1, part 2 (similarity): {d}\n", .{s});

    std.debug.assert(s == 24931009);
    std.debug.assert(d == 2066446);
}
