# Pac-Man

A recreation of the 1980 arcade Pac-Man in Godot 4.7, with the original ghost AI
and a procedurally generated maze for every level after the first.

## Arcade behaviour

The ghosts use their original targeting rules. Blinky chases Pac-Man directly,
Pinky aims four tiles ahead — including the up-direction overflow bug from the
1980 ROM — Inky mirrors Blinky through a point two tiles ahead of Pac-Man, and
Clyde breaks off and runs for his corner inside eight tiles.

Also implemented from the arcade:

- Scatter and chase waves on the original timers, with the forced reversal on
  every switch, and the four tiles where a ghost may not turn upward.
- Ghost house release by personal dot counters with the no-dot release timer,
  and Cruise Elroy speeding Blinky up as the board empties.
- Per-level speed and frightened-duration tables, 200/400/800/1600 ghost chains,
  fruit at 70 and 170 dots eaten, tunnel slowdown, extra life at 10,000.

Past the arcade tables, ghosts keep getting faster on every level, so a run ends
eventually no matter how well it is played. Frightened and tunnel speeds stay
capped below Pac-Man's, so energizers and the tunnel remain real escapes.

## Procedurally generated mazes

Level 1 is the arcade board. Every level after it is generated at load time and
drawn in a new colour.

The generator lays a lattice of one-tile corridors over the board, then deletes
random corridor segments in mirrored pairs, keeping a deletion only if the maze
still satisfies every rule. Deleting segments is what merges neighbouring wall
rectangles into the L, T and comb shapes that make a maze read as hand-drawn
instead of as a grid.

Every generated maze is guaranteed to be left-right symmetric, have every tile
reachable from the start through the tunnel, contain no dead ends, contain no
2x2 open area, keep the ghost house and tunnel rows identical to the arcade
board, and carry four energizers with at least 185 dots. Across 150 seeds tested
in-engine: no invalid mazes, no fallbacks, 192-260 dots, about 36 ms each.

## Drawn and synthesized in code

The only assets are the 16x16 sprites in `pacman-art/`. Everything else is
generated at runtime:

- Maze walls are drawn as inset rounded outlines per wall tile, which produces
  the arcade's double-line look and means a new maze needs no new art.
- HUD and menu text uses a 5x7 bitmap font drawn with rectangles, so there is no
  font file.
- Sound effects are square waves synthesized into `AudioStreamWAV` at startup,
  so there are no audio files to import and nothing extra to ship on the web.

## Controls

| Input | Action |
| --- | --- |
| Arrow keys / WASD | Move |
| Enter / Space | Start, confirm a menu choice |
| Swipe | Move (touch screens and mouse drag) |
| Tap | Start, pick a menu option |

The between-levels panel offers CONTINUE and QUIT. QUIT closes the game in a
desktop build. Browsers do not let a page close itself, so in a web build the
option reads MAIN MENU and returns to the title screen. The choice is made at
runtime from `OS.has_feature("web")`, not per preset.

There is a debug panel on F1 in debug builds only, gated on
`OS.is_debug_build()`, with level jumps, maze reroll, invincibility and frozen
ghosts. Exported builds have no way to reach it.

## Running it

Open the project in Godot 4.7 and press F5. The main scene is
`scenes/main.tscn`.

The web preset exports to `docs/` and is single-threaded, so the build needs no
cross-origin isolation headers and runs on any plain static host. The copy
served on the portfolio has a patched `index.html` that shares an `AudioContext`
with the parent page, so a re-export should replace everything in that folder
except `index.html`.

## itch.io

The `itch.io` preset exports to `build/itch/`. It is the same single-threaded
web build as `Web`, with two differences: it leaves `build/` out of the pack,
and its `head_include` only resumes the audio context on the first input
instead of borrowing one from a parent page. itch.io serves the game in a
cross-origin iframe, so the parent page cannot be reached anyway.

To publish, zip the contents of `build/itch/` with `index.html` at the root of
the zip, not inside a folder. Then, on the itch.io project page:

- Kind of project: HTML. Upload the zip and tick "This file will be played in
  the browser".
- Viewport: 448 x 576 or a multiple of it, such as 672 x 864. The canvas
  scales to whatever size is set.
- Tick "Mobile friendly" (portrait) and "Fullscreen button".
- Leave "SharedArrayBuffer support" off. The build does not use threads.

## Project layout

| File | Role |
| --- | --- |
| `scripts/pm.gd` | Constants: the arcade maze, sizing, per-level speed and frightened tables, the ghost speed ramp, scatter-chase waves, fruit table, per-level colour |
| `scripts/maze_gen.gd` | Procedural maze generator and its validity rules |
| `scripts/board.gd` | Tile grid, pellets, and the procedural wall rendering |
| `scripts/actor.gd` | Base tile-to-tile mover: grid stepping, tunnel wrap, mid-segment reversal |
| `scripts/player.gd` | Pac-Man: input buffering, chomp animation, death animation |
| `scripts/ghost.gd` | Ghost AI, house entry and exit paths, frightened and eaten states |
| `scripts/game.gd` | Game loop, scoring, lives, levels, fruit, ghost release, audio routing |
| `scripts/hud.gd` | Title screen, between-levels menu, HUD |
| `scripts/px_font.gd` | The 5x7 bitmap font |
| `scripts/sfx.gd` | Runtime sound synthesis |
