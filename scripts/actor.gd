class_name Actor
extends Node2D

var board: Board
var tile := Vector2i.ZERO
var dir := PM.NONE
var progress := 0.0
var speed := 100.0

func place(t: Vector2i, d: Vector2i, p: float = 0.0) -> void:
	tile = t
	dir = d
	progress = p
	sync_position()

func sync_position() -> void:
	position = PM.tile_center(tile) + Vector2(dir) * (PM.TILE * progress)

func next_tile() -> Vector2i:
	return wrap_tile(tile + dir)

func wrap_tile(t: Vector2i) -> Vector2i:
	if t.y == PM.TUNNEL_ROW:
		if t.x < 0:
			return Vector2i(PM.COLS - 1, t.y)
		if t.x >= PM.COLS:
			return Vector2i(0, t.y)
	return t

func in_tunnel() -> bool:
	return tile.y == PM.TUNNEL_ROW and (tile.x <= 5 or tile.x >= 22)

func reverse() -> void:
	if dir == PM.NONE:
		return
	tile = wrap_tile(tile + dir)
	dir = -dir
	progress = 1.0 - progress
	sync_position()

func advance(delta: float) -> void:
	var dist := speed * delta
	var guard := 0
	while dist > 0.0 and dir != PM.NONE:
		guard += 1
		if guard > 64:
			break
		var remain := (1.0 - progress) * float(PM.TILE)
		if dist < remain:
			progress += dist / float(PM.TILE)
			dist = 0.0
		else:
			dist -= remain
			tile = wrap_tile(tile + dir)
			progress = 0.0
			on_arrive()
	sync_position()

func on_arrive() -> void:
	pass
