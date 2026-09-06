class_name PM
extends RefCounted

const TILE := 16
const COLS := 28
const ROWS := 31
const HUD_TOP_ROWS := 3
const HUD_BOTTOM_ROWS := 2
const ORIGIN := Vector2(0, HUD_TOP_ROWS * TILE)
const VIEW_SIZE := Vector2i(COLS * TILE, (ROWS + HUD_TOP_ROWS + HUD_BOTTOM_ROWS) * TILE)
const CENTER_X := float(COLS * TILE) * 0.5

const SPRITE_SCALE := 1.75
const SPRITE_RADIUS := 13.0

const UP := Vector2i(0, -1)
const DOWN := Vector2i(0, 1)
const LEFT := Vector2i(-1, 0)
const RIGHT := Vector2i(1, 0)
const NONE := Vector2i(0, 0)
const TURN_ORDER := [UP, LEFT, DOWN, RIGHT]

const TUNNEL_ROW := 14
const HOUSE_EXIT := Vector2(13.5, 11.0)
const HOUSE_INNER := Vector2(13.5, 14.0)
const FRUIT_TILE := Vector2(13.5, 17.0)
const PLAYER_START_TILE := Vector2i(14, 23)
const NO_UP_TILES := [Vector2i(12, 11), Vector2i(15, 11), Vector2i(12, 23), Vector2i(15, 23)]

const BASE_SPEED := 151.515

const GHOST_RAMP_PER_LEVEL := 0.015
const GHOST_SPEED_CAP := 1.45
const GHOST_FRIGHT_CAP := 0.85
const GHOST_TUNNEL_CAP := 0.90

const ST_READY := 0
const ST_PLAY := 1
const ST_DYING := 2
const ST_LEVEL_CLEAR := 3
const ST_GAME_OVER := 4
const ST_GHOST_EATEN := 5
const ST_TITLE := 6
const ST_LEVEL_MENU := 7

const C_WALL_FLASH := Color("f8f8f8")
const C_DOOR := Color("ffb8ff")
const C_PELLET := Color("ffb897")
const C_TEXT := Color("f8f8f8")
const C_YELLOW := Color("ffff00")
const C_RED := Color("ff0000")
const C_CYAN := Color("00ffff")
const C_PINK := Color("ffb8ff")
const C_ORANGE := Color("ffb852")
const C_FRIGHT := Color("2121ff")
const C_BG := Color("000000")

const MAZE_CLASSIC := [
	"############################",
	"#............##............#",
	"#.####.#####.##.#####.####.#",
	"#o####.#####.##.#####.####o#",
	"#.####.#####.##.#####.####.#",
	"#..........................#",
	"#.####.##.########.##.####.#",
	"#.####.##.########.##.####.#",
	"#......##....##....##......#",
	"######.##### ## #####.######",
	"######.##### ## #####.######",
	"######.##          ##.######",
	"######.## ###--### ##.######",
	"######.## #      # ##.######",
	"      .   #      #   .      ",
	"######.## #      # ##.######",
	"######.## ######## ##.######",
	"######.##          ##.######",
	"######.## ######## ##.######",
	"######.## ######## ##.######",
	"#............##............#",
	"#.####.#####.##.#####.####.#",
	"#.####.#####.##.#####.####.#",
	"#o..##.......  .......##..o#",
	"###.##.##.########.##.##.###",
	"###.##.##.########.##.##.###",
	"#......##....##....##......#",
	"#.##########.##.##########.#",
	"#.##########.##.##########.#",
	"#..........................#",
	"############################",
]

static func level_color(level: int) -> Color:
	if level <= 1:
		return Color("2121de")
	return Color.from_hsv(fmod(float(level) * 0.137 + 0.58, 1.0), 0.82, 0.90)

static func tile_center(t: Vector2i) -> Vector2:
	return ORIGIN + Vector2(t.x + 0.5, t.y + 0.5) * TILE

static func tile_center_f(t: Vector2) -> Vector2:
	return ORIGIN + Vector2(t.x + 0.5, t.y + 0.5) * TILE

static func level_data(level: int) -> Dictionary:
	var d := {
		"pac": 0.90, "pac_fright": 1.00,
		"ghost": 0.95, "ghost_fright": 0.60, "ghost_tunnel": 0.50,
		"elroy1": 40, "elroy1_speed": 1.00, "elroy2": 20, "elroy2_speed": 1.05,
		"fright": 1.0, "flashes": 3,
	}
	match level:
		1:
			d = {"pac": 0.80, "pac_fright": 0.90, "ghost": 0.75, "ghost_fright": 0.50,
				"ghost_tunnel": 0.40, "elroy1": 20, "elroy1_speed": 0.80, "elroy2": 10,
				"elroy2_speed": 0.85, "fright": 6.0, "flashes": 5}
		2:
			d = {"pac": 0.90, "pac_fright": 0.95, "ghost": 0.85, "ghost_fright": 0.55,
				"ghost_tunnel": 0.45, "elroy1": 30, "elroy1_speed": 0.90, "elroy2": 15,
				"elroy2_speed": 0.95, "fright": 5.0, "flashes": 5}
		3:
			d = {"pac": 0.90, "pac_fright": 0.95, "ghost": 0.85, "ghost_fright": 0.55,
				"ghost_tunnel": 0.45, "elroy1": 40, "elroy1_speed": 0.90, "elroy2": 20,
				"elroy2_speed": 0.95, "fright": 4.0, "flashes": 5}
		4:
			d = {"pac": 0.90, "pac_fright": 0.95, "ghost": 0.85, "ghost_fright": 0.55,
				"ghost_tunnel": 0.45, "elroy1": 40, "elroy1_speed": 0.90, "elroy2": 20,
				"elroy2_speed": 0.95, "fright": 3.0, "flashes": 5}
		5:
			d = {"pac": 1.00, "pac_fright": 1.00, "ghost": 0.95, "ghost_fright": 0.60,
				"ghost_tunnel": 0.50, "elroy1": 40, "elroy1_speed": 1.00, "elroy2": 20,
				"elroy2_speed": 1.05, "fright": 2.0, "flashes": 5}
		_:
			if level >= 19:
				d["fright"] = 0.0
				d["flashes"] = 0
				d["pac_fright"] = 0.90
			elif level >= 17:
				d["fright"] = 1.0 if level == 17 else 0.0
			else:
				d["fright"] = maxf(1.0, 6.0 - float(level) * 0.25)
	_apply_ghost_ramp(d, level)
	return d

static func ghost_ramp(level: int) -> float:
	return maxf(float(level - 1), 0.0) * GHOST_RAMP_PER_LEVEL


static func _apply_ghost_ramp(d: Dictionary, level: int) -> void:
	var ramp := ghost_ramp(level)
	if ramp <= 0.0:
		return
	d["ghost"] = minf(float(d["ghost"]) + ramp, GHOST_SPEED_CAP)
	d["ghost_tunnel"] = minf(float(d["ghost_tunnel"]) + ramp * 0.6, GHOST_TUNNEL_CAP)
	d["ghost_fright"] = minf(float(d["ghost_fright"]) + ramp * 0.5, GHOST_FRIGHT_CAP)
	d["elroy1_speed"] = minf(float(d["elroy1_speed"]) + ramp, GHOST_SPEED_CAP + 0.05)
	d["elroy2_speed"] = minf(float(d["elroy2_speed"]) + ramp, GHOST_SPEED_CAP + 0.10)

static func wave_table(level: int) -> Array:
	if level == 1:
		return [7.0, 20.0, 7.0, 20.0, 5.0, 20.0, 5.0, -1.0]
	elif level <= 4:
		return [7.0, 20.0, 7.0, 20.0, 5.0, 1033.0, 0.02, -1.0]
	return [5.0, 20.0, 5.0, 20.0, 5.0, 1037.0, 0.02, -1.0]

static func fruit_for_level(level: int) -> Dictionary:
	var table := [
		{"tex": "strawberry", "points": 100},
		{"tex": "strawberry", "points": 300},
		{"tex": "apple", "points": 500},
		{"tex": "apple", "points": 700},
		{"tex": "strawberry", "points": 1000},
		{"tex": "apple", "points": 2000},
		{"tex": "strawberry", "points": 3000},
		{"tex": "apple", "points": 5000},
	]
	return table[mini(level, table.size()) - 1]
