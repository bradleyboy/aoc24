const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

pub fn run(alloc: Allocator) !void {
    const input = try std.fs.cwd().readFileAlloc(alloc, "input/day5.txt", std.math.maxInt(usize));
    defer alloc.free(input);

    var it = std.mem.split(u8, input, "\n");
    var in_rules = true;
    var valid_updates_middle_page_sum: usize = 0;

    var rules = AutoHashMap(u64, AutoHashMap(u64, bool)).init(
        alloc,
    );
    defer {
        var deinit_it = rules.iterator();
        while (deinit_it.next()) |r| {
            r.value_ptr.deinit();
        }
        rules.deinit();
    }

    outer: while (it.next()) |line| {
        if (line.len == 0) {
            in_rules = false;
            continue;
        }

        if (in_rules) {
            var rule_it = std.mem.split(u8, line, "|");
            const root_page_s = rule_it.next();
            const target_page_s = rule_it.next();

            if (root_page_s == null or target_page_s == null) {
                return error.InvalidRule;
            }

            const root_page = try std.fmt.parseInt(u64, root_page_s.?, 10);
            const target_page = try std.fmt.parseInt(u64, target_page_s.?, 10);

            var existing = rules.getPtr(root_page);

            if (existing == null) {
                var list = AutoHashMap(u64, bool).init(alloc);
                try list.put(target_page, true);
                try rules.put(root_page, list);
            } else {
                try existing.?.put(target_page, true);
            }
        } else {
            var update_it = std.mem.split(u8, line, ",");
            var pages = ArrayList(u64).init(alloc);
            defer pages.deinit();

            while (update_it.next()) |page| {
                const page_int = try std.fmt.parseInt(u64, page, 10);
                try pages.append(page_int);
            }

            const pages_slice = try pages.toOwnedSlice();
            defer alloc.free(pages_slice);

            // this is a mess, but basically it does this:
            // * for each item in the rules list, search forward to make sure all
            //   following pages are in its rules
            //* OR, if not found, look in the target pages rules and make sure this
            //  page is NOT there, as that would be invalid.
            var p: usize = 0;
            var fixed = false;

            rule: while (p < pages_slice.len - 1) {
                const page = pages_slice[p];
                const page_rules = rules.get(page) orelse AutoHashMap(u64, bool).init(alloc);

                for (p + 1..pages_slice.len) |t| {
                    const found = page_rules.get(pages_slice[t]) orelse false;

                    if (found) {
                        continue;
                    }

                    const target_page_rule = rules.get(pages_slice[t]) orelse {
                        continue :outer;
                    };
                    var target_page_rule_it = target_page_rule.iterator();

                    while (target_page_rule_it.next()) |r| {
                        if (r.key_ptr.* == page) {
                            // Out of order, so swap them and return to the loop without
                            // incrementing p so we try this index again.
                            std.mem.swap(u64, &pages_slice[p], &pages_slice[t]);
                            fixed = true;
                            continue :rule;
                        }
                    }
                }

                p += 1;
            }

            if (fixed) {
                valid_updates_middle_page_sum += pages_slice[pages_slice.len / 2];
            }
        }
    }

    std.debug.print("day 5, valid (fixed) updates: {d}", .{valid_updates_middle_page_sum});
}
