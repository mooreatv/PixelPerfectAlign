# PixelPerfectAlign
Pixel perfect demonstration / alignment WoW addon

Demonstrates how to draw on screen lines of exactly 1 pixel width/height using a grid of crosses as example.

It will automatically use a square even horizontal and vertical spacing of the crosses for standard aspect ratio like 4:3, 16:9, 16:10.

Can be used for alignment of your UI or before pretty screenshot or just to see exactly 1 pixel grid/crosses rendered.

Use `/ppa` to see commands or `/ppa conf` for config options, `/ppa toggle` to toggle grid on/off, `/ppa info` for display info.

There is also an optional keybinding for toggling the grid on/off as well as the display info.

If you find a case where the crosses aren't showing evenly or not exactly 1 pixel; please take a screen shot and comment about your setup.

Most of the heavy lifting code is in https://github.com/mooreatv/MoLib a reusable library
