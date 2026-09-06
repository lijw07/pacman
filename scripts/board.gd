class_name Board
extends Node2D

const EMPTY := 0
const WALL := 1
const DOOR := 2

const INSET := 6.0
const LINE_W := 1.6

var grid: Array = []
var pellets: Dictionary = {}
var total_pellets := 0
var pellets_eaten := 0
var flash_white := false
var maze_rows: Array = PM.MAZE_CLASSIC
var wall_color := Color("2121de")

var _blink_on := true
var _blink_timer := 0.0



func build(rows: Array, color: Color) -> void:
	maze_rows = rows
	wall_color = color
	grid.clear()
	pellets.clear()
	pellets_eaten = 0
	for y in PM.ROWS:
		var row: Array[int] = []
		var line: String = maze_rows[y]
		for x in PM.COLS:
			var ch := line[x]
			match ch:
				"#":
					row.append(WALL)
				"-":
					row.append(DOOR)
				".":
					row.append(EMPTY)
					pellets[Vector2i(x, y)] = 1
				"o":
					row.append(EMPTY)
					pellets[Vector2i(x, y)] = 2
				_:
					row.append(EMPTY)
		grid.append(row)
	total_pellets = pellets.size()
	queue_redraw()

func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= 0.16:
		_blink_timer = 0.0
		_blink_on = not _blink_on
		queue_redraw()

func cell(t: Vector2i) -> int:
	if t.y < 0 or t.y >= PM.ROWS:
		return WALL
	if t.x < 0 or t.x >= PM.COLS:
		return WALL if t.y != PM.TUNNEL_ROW else EMPTY
	return grid[t.y][t.x]

func is_wall(t: Vector2i) -> bool:
	return cell(t) == WALL

func walkable(t: Vector2i, allow_door: bool = false) -> bool:
	var c := cell(t)
	if c == WALL:
		return false
	if c == DOOR:
		return allow_door
	return true

func pellet_at(t: Vector2i) -> int:
	return pellets.get(t, 0)

func eat(t: Vector2i) -> int:
	var kind: int = pellets.get(t, 0)
	if kind != 0:
		pellets.erase(t)
		pellets_eaten += 1
		queue_redraw()
	return kind

func pellets_left() -> int:
	return pellets.size()

func _open(x: int, y: int) -> bool:
	if y < 0 or y >= PM.ROWS or x < 0 or x >= PM.COLS:
		return true
	return grid[y][x] == EMPTY

func _draw() -> void:
	var col := PM.C_WALL_FLASH if flash_white else wall_color
	for y in PM.ROWS:
		for x in PM.COLS:
			if grid[y][x] == EMPTY:
				continue
			_draw_tile(x, y, col)
	_draw_door()
	if not flash_white:
		_draw_pellets()

func _draw_tile(x: int, y: int, col: Color) -> void:
	var p := PM.ORIGIN + Vector2(x, y) * PM.TILE
	var t := float(PM.TILE)
	var i := INSET
	var n := _open(x, y - 1)
	var s := _open(x, y + 1)
	var w := _open(x - 1, y)
	var e := _open(x + 1, y)
	var nw := _open(x - 1, y - 1)
	var ne := _open(x + 1, y - 1)
	var sw := _open(x - 1, y + 1)
	var se := _open(x + 1, y + 1)

	if n:
		draw_line(p + Vector2(i if w else 0.0, i), p + Vector2(t - (i if e else 0.0), i), col, LINE_W)
	if s:
		draw_line(p + Vector2(i if w else 0.0, t - i), p + Vector2(t - (i if e else 0.0), t - i), col, LINE_W)
	if w:
		draw_line(p + Vector2(i, i if n else 0.0), p + Vector2(i, t - (i if s else 0.0)), col, LINE_W)
	if e:
		draw_line(p + Vector2(t - i, i if n else 0.0), p + Vector2(t - i, t - (i if s else 0.0)), col, LINE_W)

	if n and w:
		_arc(p + Vector2(i, i), i, PI, TAU * 0.75, col)
	if n and e:
		_arc(p + Vector2(t - i, i), i, TAU * 0.75, TAU, col)
	if s and e:
		_arc(p + Vector2(t - i, t - i), i, 0.0, PI * 0.5, col)
	if s and w:
		_arc(p + Vector2(i, t - i), i, PI * 0.5, PI, col)

	if not n and not w and nw:
		_arc(p, i, 0.0, PI * 0.5, col)
	if not n and not e and ne:
		_arc(p + Vector2(t, 0.0), i, PI * 0.5, PI, col)
	if not s and not e and se:
		_arc(p + Vector2(t, t), i, PI, TAU * 0.75, col)
	if not s and not w and sw:
		_arc(p + Vector2(0.0, t), i, TAU * 0.75, TAU, col)

func _arc(c: Vector2, r: float, a0: float, a1: float, col: Color) -> void:
	draw_arc(c, r, a0, a1, 8, col, LINE_W)

func _draw_door() -> void:
	var p := PM.ORIGIN + Vector2(13, 12) * PM.TILE
	draw_rect(Rect2(p, Vector2(PM.TILE * 2, PM.TILE)), PM.C_BG)
	draw_rect(Rect2(p + Vector2(0, PM.TILE * 0.5 - 1.5), Vector2(PM.TILE * 2, 3)), PM.C_DOOR)

func _draw_pellets() -> void:
	for t in pellets:
		var kind: int = pellets[t]
		var c := PM.tile_center(t)
		if kind == 1:
			draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), PM.C_PELLET)
		elif _blink_on:
			draw_circle(c, 6.5, PM.C_PELLET)
