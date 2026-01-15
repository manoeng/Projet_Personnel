const std = @import("std");
const rl = @import("raylib");

// Size of game / window properties
pub const size = 50;
pub const screen_width = 1000;
pub const screen_height = 600;
pub const map_width: u16 = @intCast(screen_width / size);
pub const map_height: u16 = @intCast(screen_height / size);

pub const Grid = [map_height][map_width]u8; // Size of matrix

pub var game_over: bool = false; // When game ends

// Main logic struct
pub const Map = struct {
    data: Grid,
    tile_size: f32 = size,

    pub fn draw(self: Map) void {
        for (self.data, 0..) |row, y| {
            for (row, 0..) |tile, x| {
                const fx: f32 = @floatFromInt(x);
                const fy: f32 = @floatFromInt(y);
                const rect = rl.Rectangle{ .x = fx * self.tile_size, .y = fy * self.tile_size, .width = self.tile_size, .height = self.tile_size };

                switch (tile) {
                    1 => rl.drawRectangleRec(rect, .gray), // Wall
                    2 => rl.drawRectangleRec(rect, .orange), // Movable Block
                    3 => rl.drawCircle(@intFromFloat(fx * self.tile_size + self.tile_size / 2),
                                       @intFromFloat(fy * self.tile_size + self.tile_size / 2),
                                       self.tile_size / 2,
                                       .purple),
                    4 => rl.drawRectangleRec(rect, .green), // Goal
                    else => {},
                }
            }
        }
    }

    // This checks if a SPECIFIC point (x, y) is inside a solid tile
    pub fn getTileAt(self: Map, x: f32, y: f32) u8 {
        if (x < 0 or x > screen_width or y < 0 or y > screen_height) {
            return 1;
        }
        const ix: usize = @intFromFloat(x / self.tile_size);
        const iy: usize = @intFromFloat(y / self.tile_size);
        return self.data[iy][ix];
    }

    // Logic for pushing and moving
    pub fn updateLogic(self: *Map, px: f32, py: f32, nextX: f32, nextY: f32) struct { x: f32, y: f32, win: bool } {
        // Check all 4 corners of the player's box
        const pad: f32 = 2; // Padding to make the hitbox smaller
        const corners: [4][2]f32 = .{
            .{ nextX + pad, nextY + pad }, // Top Left
            .{ nextX + size - pad, nextY + pad }, // Top Right
            .{ nextX + pad, nextY + size - pad }, // Bottom Left
            .{ nextX + size - pad, nextY + size - pad }, // Bottom Right
        };

        for (corners) |c| {
            const tile = self.getTileAt(c[0], c[1]);

            if (tile == 1) return .{ .x = px, .y = py, .win = false }; // Hit a wall

            if (tile == 4) return .{ .x = nextX, .y = nextY, .win = true }; // Hit the goal

            // Check tile position of every corner
            const ix: usize = @intFromFloat(c[0] / self.tile_size);
            const iy: usize = @intFromFloat(c[1] / self.tile_size);

            if (tile == 2) {
                // Determine push direction based on movement
                const dx: i32 = if (nextX > px) 1 else if (nextX < px) -1 else 0;
                const dy: i32 = if (nextY > py) 1 else if (nextY < py) -1 else 0;

                const target_x = @as(i32, @intCast(ix)) + dx;
                const target_y = @as(i32, @intCast(iy)) + dy;

                if (target_x >= 0 and target_x < map_width and target_y >= 0 and target_y < map_height) {
                    if (self.data[@intCast(target_y)][@intCast(target_x)] == 0 or self.data[@intCast(target_y)][@intCast(target_x)] == 3) {
                        self.data[@intCast(target_y)][@intCast(target_x)] = 2;
                        self.data[iy][ix] = 0;
                        return .{ .x = nextX, .y = nextY, .win = false };
                    }
                }
                return .{ .x = px, .y = py, .win = false }; // Block is stuck
            }

            if (tile == 3) {
                for (self.data, 0..) |row, y| {
                    for (row, 0..) |target_tile, x| {
                        // Find another portal
                        if (target_tile == 3 and (x != ix or y != iy)) {
                            // Delete the portal the player lands on
                            self.data[y][x] = 0; 

                            // Set the new position the the location of a second portal
                            const newX = @as(f32, @floatFromInt(x)) * self.tile_size;
                            const newY = @as(f32, @floatFromInt(y)) * self.tile_size;

                            return .{ .x = newX, .y = newY, .win = false };
                        }
                    }
                }
            }
        }
        return .{ .x = nextX, .y = nextY, .win = false };
    }
};

// Where the level design is created
pub fn Levels(id: u8, stX: *f32, stY: *f32) Grid {
    // Create an empty matrix (every position is set to 0)
    var matrix: Grid = .{ .{0} ** map_width } ** map_height;
    _ = &matrix; // Ensure there is no error if the variable is never changed

    switch (id) {
        1 => {
            stX.* = 0 * size; stY.* = 0 * size;
            for (0..map_width) |i| {
                matrix[5][i] = 1;
            }
            matrix[5][9] = 2;
            matrix[11][19] = 4;
        },
        2 => {
            stX.* = 0 * size; stY.* = 0 * size;
            for (0..map_height) |i| {
                matrix[i][7] = 1;
                matrix[i][8] = 1;
                matrix[i][9] = 1;
            }
            matrix[2][14] = 3;
            matrix[10][2] = 3;
            matrix[11][19] = 4;
        },
        3 => {
            stX.* = 0 * size; stY.* = 0 * size;
            for (0..map_height) |i| {
                matrix[i][10] = 1; 
            }
            matrix[6][10] = 2; 
            matrix[6][15] = 4; 
            matrix[5][15] = 1; matrix[7][15] = 1; matrix[7][14] = 1; matrix[6][16] = 1;
        },
        4 => {
            stX.* = 0 * size; stY.* = 0 * size;
            for (0..5) |i| { matrix[i][5] = 1; }
            for (0..5) |i| { matrix[5][i] = 1; }
            matrix[3][6] = 1; matrix[4][7] = 1; matrix[5][6] = 1; matrix[4][5] = 2;
            matrix[2][2] = 3; matrix[2][17] = 3;
            for (7..12) |i| { matrix[10][i] = 1; }
            matrix[11][12] = 1; matrix[11][6] = 1; matrix[11][11] = 3; matrix[11][7] = 4;
        },
        5 => {
            stX.* = 1 * size; stY.* = 6 * size;
            for (0..12) |i| { matrix[i][10] = 1; }
            matrix[6][10] = 3;
            for (11..map_width) |i| { matrix[5][i] = 1; }
            matrix[2][15] = 3;
            matrix[8][15] = 4;
            matrix[1][1] = 2;
        },
        6 => {
            
        },
        else => { stX.* = (screen_width - size) / 2; stY.* = (screen_height - size) / 2; game_over = true; },
    }
    return matrix;
}
