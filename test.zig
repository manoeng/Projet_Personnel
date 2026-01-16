const std = @import("std");

fn array() ![]u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var list = std.ArrayList(u8){};
    defer list.deinit(allocator);

    // Pass the allocator only when you actually use it
    for (0..5) |i| {
        try list.append(allocator, @intCast(i+1));
    }
    std.debug.print("List: {any}\n", .{list});

    return list.items;
}

pub fn main() !void {
    const boolean: bool = true;
    const arr = try array();
    _ = arr;

    if (1 == 2 or boolean) {
        std.debug.print("YES\n", .{});
    }
}

fn addNum(input:*i8) void {
    input.* += 10;
}