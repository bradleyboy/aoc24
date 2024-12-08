const std = @import("std");
const day1 = @import("./days/1.zig");
const day2 = @import("./days/2.zig");
const day3 = @import("./days/3.zig");
const day4 = @import("./days/4.zig");
const day5 = @import("./days/5.zig");
const day6 = @import("./days/6.zig");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try day1.run(allocator);
    try day2.run(allocator);
    try day3.run(allocator);
    try day4.run(allocator);
    try day5.run(allocator);
    try day6.run(allocator);
}
