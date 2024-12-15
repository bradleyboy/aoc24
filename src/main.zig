const std = @import("std");
const day1 = @import("./days/1.zig");
const day2 = @import("./days/2.zig");
const day3 = @import("./days/3.zig");
const day4 = @import("./days/4.zig");
const day5 = @import("./days/5.zig");
const day6 = @import("./days/6.zig");
const day7 = @import("./days/7.zig");
const day8 = @import("./days/8.zig");
const day9 = @import("./days/9.zig");
const day10 = @import("./days/10.zig");
const day11 = @import("./days/11.zig");
const day14 = @import("./days/14.zig");

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
    try day7.run(allocator);
    try day8.run(allocator);
    try day9.run(allocator);
    try day10.run(allocator);
    try day11.run(allocator);
    // 12
    // 13
    try day14.run(allocator);
}
