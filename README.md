# Pac-Man

A recreation of the 1980 arcade Pac-Man in Godot 4.7, with the original ghost
AI and a procedurally generated maze for every level after the first.

**[Play it in the browser](https://lijw07.github.io/pacman/)**

![Gameplay](screenshots/gameplay.png)

## Arcade behaviour, not an approximation

- The four ghosts use their original targeting rules. Blinky chases Pac-Man
  directly, Pinky aims four tiles ahead — including the up-direction overflow
  bug from the 1980 ROM — Inky mirrors Blinky through a point two tiles ahead of
  Pac-Man, and Clyde breaks off and runs for his corner inside eight tiles.
- Scatter and chase waves on the arcade timers, with the forced reversal on
  every switch, and the four tiles where a ghost may not turn upward.
- Ghost house release by personal dot counters with the no-dot release timer,
  and Cruise Elroy speeding Blinky up as the board empties.
- Per-level speed and frightened-duration tables, 200/400/800/1600 ghost chains,
  fruit at 70 and 170 dots eaten, tunnel slowdown, extra life at 10,000.

Ghosts also keep getting faster every level past the arcade tables, so the run
ends eventually no matter how well you play.

## Procedurally generated mazes

Level 1 is the arcade board. Every level after it is generated at load time and
drawn in a new colour.

![Generated mazes](screenshots/generated-mazes.png)

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

The only assets in the repo are the 16x16 sprites in `pacman-art/`. Everything
else is generated at runtime:

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

## Running it

Open the project in Godot 4.7 and press F5. The main scene is
`scenes/main.tscn`.

The playable web build lives in `docs/`, which is what GitHub Pages serves.
`export_presets.cfg` exports straight there, so Project > Export > Web >
Export Project overwrites it and you commit the result. The preset is
single-threaded, so it needs no cross-origin isolation headers and runs on any
plain static host.

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
