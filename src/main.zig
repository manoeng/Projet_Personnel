// Libraries
const std = @import("std");
const rl = @import("raylib");
const map = @import("map.zig");

// Imports
const Map = map.Map;
const Levels = map.Levels;
const size = map.size;
const screen_width = map.screen_width;
const screen_height = map.screen_height;

// Player properties
var posX: f32 = 0;
var posY: f32 = 0;
const speed: f32 = 300;

pub fn main() !void {
    // Init window{{{
    rl.initWindow(screen_width, screen_height, "Projet Personnel");
    defer rl.closeWindow(); // Close window when function is out of scope

    var level: u8 = 1;
    var game_map = Map{ .data = Levels(level, &posX, &posY) };

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or escape key

        // Calculate how much time it takes for one frame to happen (delta time)
        const dt = rl.getFrameTime();

        // Player movement request X axis
        var nextX = posX;

        // Movement (x axis)
        if (rl.isKeyDown(.right)) nextX += speed * dt;
        if (rl.isKeyDown(.left)) nextX -= speed * dt;

        if (nextX != posX) {
            // Pass (posX, posY) as the "old" and (nextX, posY) as the "new"
            const checkX = game_map.updateLogic(posX, posY, nextX, posY);
            posX = checkX.x;
            posY = checkX.y;
            // If we hit a goal during X movement, handle it
            if (checkX.win) handleWin(&game_map, &posX, &posY, &level);
        }

        // Player movement request Y axis
        var nextY = posY;

        // Movement (y axis)
        if (rl.isKeyDown(.down)) nextY += speed * dt;
        if (rl.isKeyDown(.up)) nextY -= speed * dt;

        if (nextY != posY) {
            // Pass the NEW posX and the target nextY
            const checkY = game_map.updateLogic(posX, posY, posX, nextY);
            posY = checkY.y;
            posX = checkY.x;
            // If goal is reached during y movement, handle it
            if (checkY.win) handleWin(&game_map, &posX, &posY, &level);
        }

        // Level reset
        if (rl.isKeyDown(.r)) {
            // Reset the level
            game_map.data = Levels(level, &posX, &posY);
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing(); // Stops drawing when out of scope
        rl.clearBackground(.white); // Set background color

        // Level
        game_map.draw();
        // Player
        rl.drawRectangleV(.{ .x = posX, .y = posY }, .{ .x = size, .y = size }, .blue);
        rl.drawFPS(5, 5); // Show FPS for testing

        // Text to display
        var buf: [64]u8 = undefined;
        var txt_size: u8 = 20;
        _ = &buf;
        var text = try std.fmt.bufPrintZ(&buf, "Niveau {}", .{level});

        // Check if the player finished all the levels
        var game_over = map.game_over;
        _ = &game_over;
        if (game_over) {
            text = try std.fmt.bufPrintZ(&buf, "Bravo! Tu as gagné!", .{});
            txt_size = 40;
        }

        const txt_width = rl.measureText(text, txt_size);
        rl.drawText(text, screen_width / 2 - @divTrunc(txt_width, 2), 5, txt_size, .black);
    }// }}}
}

fn handleWin(game_map: *Map, px: *f32, py: *f32, level_id: *u8) void {
    level_id.* += 1;
    game_map.data = Levels(level_id.*, px, py);
}
