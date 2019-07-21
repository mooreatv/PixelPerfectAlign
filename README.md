# PixelPerfectAlign
Pixel perfect demonstration / alignment WoW addon

Demonstrates how to draw on screen lines of exactly 1 pixel width/height using a grid of crosses as example.

Can be used for alignment of your UI or before pretty screenshot or just to see exactly 1 pixel grid/crosses rendered.

Use `/ppa` to see commands or `/ppa conf` for config options, `/ppa toggle` to toggle grid on/off, `/ppa info` for display info .

There is also an optional keybinding for toggling the grid on/off

If you find a case where the crosses aren't showing evenly or not exactly 1 pixel; please take a screen shot and comment about your setup.

(1.0 doesn't handle resize events so if you change your resolution or WoW window size, please /reload first, for now)

Most of the heavy lifting code is in https://github.com/mooreatv/MoLib a reusable libray
