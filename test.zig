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
    const arr = try array(); 
    _ = arr; 
}

