class_name Player
extends Actor

const ANIM_STEP := 0.055
const CYCLE := [2, 1, 0, 1]

var wanted := PM.LEFT
var frames := {}
var sprite: Sprite2D
var dying := false
var death_time := 0.0
var anim_time := 0.0
var frozen := true

func _ready() -> void:
	frames[PM.RIGHT] = _load_dir("pacman-right")
	frames[PM.LEFT] = _load_dir("pacman-left")
	frames[PM.UP] = _load_dir("pacman-up")
	frames[PM.DOWN] = _load_dir("pacman-down")
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(PM.SPRITE_SCALE, PM.SPRITE_SCALE)
	sprite.texture = frames[PM.LEFT][2]
	add_child(sprite)

func _load_dir(folder: String) -> Array:
	var out: Array = []
	for i in [1, 2, 3]:
		out.append(load("res://pacman-art/%s/%d.png" % [folder, i]))
	return out

func reset(level_speed: float) -> void:
	dying = false
	death_time = 0.0
	anim_time = 0.0
	frozen = true
	visible = true
	sprite.visible = true
	speed = PM.BASE_SPEED * level_speed
	wanted = PM.LEFT
	place(PM.PLAYER_START_TILE, PM.LEFT, 0.5)
	sprite.texture = frames[PM.LEFT][2]
	queue_redraw()

func read_input() -> void:
	if Input.is_action_pressed("pm_up"):
		wanted = PM.UP
	elif Input.is_action_pressed("pm_down"):
		wanted = PM.DOWN
	elif Input.is_action_pressed("pm_left"):
		wanted = PM.LEFT
	elif Input.is_action_pressed("pm_right"):
		wanted = PM.RIGHT

func tick(delta: float) -> void:
	if dying:
		death_time += delta
		queue_redraw()
		return
	read_input()
	if frozen:
		return
	if wanted != PM.NONE and dir != PM.NONE and wanted == -dir and progress > 0.0:
		reverse()
	if dir == PM.NONE and wanted != PM.NONE and board.walkable(wrap_tile(tile + wanted)):
		dir = wanted
	advance(delta)
	_animate(delta)

func on_arrive() -> void:
	if wanted != PM.NONE and board.walkable(wrap_tile(tile + wanted)):
		dir = wanted
	elif dir != PM.NONE and board.walkable(wrap_tile(tile + dir)):
		pass
	else:
		dir = PM.NONE

func _animate(delta: float) -> void:
	if dir == PM.NONE:
		return
	anim_time += delta
	var idx: int = CYCLE[int(anim_time / ANIM_STEP) % CYCLE.size()]
	sprite.texture = frames[dir][idx]

func start_death() -> void:
	dying = true
	death_time = 0.0
	sprite.visible = false
	queue_redraw()

func death_finished() -> bool:
	return death_time >= 1.6

func _draw() -> void:
	if not dying:
		return
	var t: float = clampf(death_time / 1.35, 0.0, 1.0)
	var open := t * PI
	if open >= PI - 0.02:
		return
	var r := PM.SPRITE_RADIUS
	var start := -PI * 0.5 + open
	var end := PI * 1.5 - open
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var steps := 32
	for i in steps + 1:
		var a: float = start + (end - start) * (float(i) / float(steps))
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, PM.C_YELLOW)
