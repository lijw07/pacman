class_name Ghost
extends Actor

enum Kind { BLINKY, PINKY, INKY, CLYDE }
enum St { HOUSE, LEAVING, OUT, ENTERING }

const HOUSE_SPEED := 0.45
const EYES_SPEED := 2.0

var kind: int = Kind.BLINKY
var state: int = St.OUT
var frightened := false
var eaten := false
var flashing := false
var flash_on := false
var elroy := 0

var home_f := Vector2.ZERO
var scatter_tile := Vector2i.ZERO
var path: Array[Vector2] = []
var bob_time := 0.0
var dot_counter := 0
var dot_limit := 0

var base_speed_mul := 0.75
var fright_speed_mul := 0.5
var tunnel_speed_mul := 0.4
var elroy1_speed := 0.8
var elroy2_speed := 0.85

var sprite: Sprite2D
var body_tex: Texture2D
var fright_tex: Texture2D
var fright_flash_tex: Texture2D
var game = null

static func kind_color(k: int) -> Color:
	match k:
		Kind.BLINKY:
			return PM.C_RED
		Kind.PINKY:
			return PM.C_PINK
		Kind.INKY:
			return PM.C_CYAN
		_:
			return PM.C_ORANGE

static func kind_texture_name(k: int) -> String:
	match k:
		Kind.BLINKY:
			return "blinky"
		Kind.PINKY:
			return "pinky"
		Kind.INKY:
			return "inky"
		_:
			return "clyde"

func setup(k: int) -> void:
	kind = k
	body_tex = load("res://pacman-art/ghosts/%s.png" % kind_texture_name(k))
	fright_tex = load("res://pacman-art/ghosts/blue_ghost.png")
	fright_flash_tex = _make_flash_texture(fright_tex)
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(PM.SPRITE_SCALE, PM.SPRITE_SCALE)
	sprite.texture = body_tex
	add_child(sprite)
	match k:
		Kind.BLINKY:
			home_f = Vector2(13.5, 14.0)
			scatter_tile = Vector2i(25, 0)
			dot_limit = 0
		Kind.PINKY:
			home_f = Vector2(13.5, 14.0)
			scatter_tile = Vector2i(2, 0)
			dot_limit = 0
		Kind.INKY:
			home_f = Vector2(11.5, 14.0)
			scatter_tile = Vector2i(27, 30)
			dot_limit = 30
		Kind.CLYDE:
			home_f = Vector2(15.5, 14.0)
			scatter_tile = Vector2i(0, 30)
			dot_limit = 60

func apply_level(d: Dictionary) -> void:
	base_speed_mul = d["ghost"]
	fright_speed_mul = d["ghost_fright"]
	tunnel_speed_mul = d["ghost_tunnel"]
	elroy1_speed = d["elroy1_speed"]
	elroy2_speed = d["elroy2_speed"]

func reset_position() -> void:
	frightened = false
	eaten = false
	flashing = false
	elroy = 0
	path.clear()
	dot_counter = 0
	visible = true
	sprite.visible = true
	bob_time = 0.0
	if kind == Kind.BLINKY:
		state = St.OUT
		place(Vector2i(14, 11), PM.LEFT, 0.5)
	else:
		state = St.HOUSE
		position = PM.tile_center_f(home_f)
		dir = PM.UP
	_refresh_sprite()
	queue_redraw()

func release() -> void:
	if state != St.HOUSE:
		return
	state = St.LEAVING
	path = [Vector2(home_f.x, 14.0), PM.HOUSE_INNER, PM.HOUSE_EXIT]

func current_speed() -> float:
	if eaten:
		return PM.BASE_SPEED * EYES_SPEED
	if state == St.HOUSE or state == St.LEAVING or state == St.ENTERING:
		return PM.BASE_SPEED * HOUSE_SPEED
	if frightened:
		return PM.BASE_SPEED * fright_speed_mul
	if in_tunnel():
		return PM.BASE_SPEED * tunnel_speed_mul
	if elroy == 2:
		return PM.BASE_SPEED * elroy2_speed
	if elroy == 1:
		return PM.BASE_SPEED * elroy1_speed
	return PM.BASE_SPEED * base_speed_mul

func tick(delta: float) -> void:
	match state:
		St.HOUSE:
			bob_time += delta
			position = PM.tile_center_f(home_f) + Vector2(0, sin(bob_time * 6.0) * 5.0)
		St.LEAVING, St.ENTERING:
			_follow_path(delta)
		St.OUT:
			speed = current_speed()
			if dir == PM.NONE:
				on_arrive()
			advance(delta)
	_refresh_sprite()

func _follow_path(delta: float) -> void:
	var step := PM.BASE_SPEED * HOUSE_SPEED * delta
	while step > 0.0 and not path.is_empty():
		var target := PM.tile_center_f(path[0])
		var to := target - position
		var d := to.length()
		if d <= step:
			position = target
			step -= d
			path.remove_at(0)
		else:
			position += to / d * step
			step = 0.0
		if to.y < -0.5:
			dir = PM.UP
		elif to.y > 0.5:
			dir = PM.DOWN
		elif to.x < -0.5:
			dir = PM.LEFT
		elif to.x > 0.5:
			dir = PM.RIGHT
	if path.is_empty():
		if state == St.LEAVING:
			state = St.OUT
			place(Vector2i(14, 11), PM.LEFT, 0.5)
		else:
			eaten = false
			state = St.HOUSE
			bob_time = 0.0
			if game != null and game.has_method("request_release"):
				game.request_release(self)

func enter_house() -> void:
	state = St.ENTERING
	path = [PM.HOUSE_EXIT, PM.HOUSE_INNER, Vector2(home_f.x, 14.0)]

func set_frightened(on: bool) -> void:
	if eaten:
		return
	if on and state == St.OUT:
		reverse_safe()
	frightened = on
	flashing = false

func reverse_safe() -> void:
	if state == St.OUT and dir != PM.NONE:
		reverse()

func on_arrive() -> void:
	if eaten and state == St.OUT and tile.y == 11 and (tile.x == 13 or tile.x == 14):
		enter_house()
		return
	var target := _target_tile()
	var best := PM.NONE
	var best_d := INF
	for d: Vector2i in PM.TURN_ORDER:
		if d == -dir and dir != PM.NONE:
			continue
		var nt := wrap_tile(tile + d)
		if not board.walkable(nt):
			continue
		if d == PM.UP and not eaten and PM.NO_UP_TILES.has(tile):
			continue
		var dist := Vector2(nt - target).length_squared()
		if dist < best_d:
			best_d = dist
			best = d
	if best == PM.NONE:
		best = -dir if dir != PM.NONE else PM.NONE
		if best != PM.NONE and not board.walkable(wrap_tile(tile + best)):
			best = PM.NONE
	if frightened and not eaten:
		var opts: Array[Vector2i] = []
		for d: Vector2i in PM.TURN_ORDER:
			if d == -dir and dir != PM.NONE:
				continue
			if not board.walkable(wrap_tile(tile + d)):
				continue
			if d == PM.UP and PM.NO_UP_TILES.has(tile):
				continue
			opts.append(d)
		if not opts.is_empty():
			best = opts[randi() % opts.size()]
	dir = best

func _target_tile() -> Vector2i:
	if eaten:
		return Vector2i(13, 11)
	if game == null:
		return scatter_tile
	var pac: Actor = game.player
	var pac_tile: Vector2i = pac.tile
	var pac_dir: Vector2i = pac.dir if pac.dir != PM.NONE else PM.LEFT
	var chase: bool = game.chase_mode
	if not chase and elroy == 0:
		return scatter_tile
	match kind:
		Kind.BLINKY:
			return pac_tile
		Kind.PINKY:
			var t := pac_tile + pac_dir * 4
			if pac_dir == PM.UP:
				t += PM.LEFT * 4
			return t
		Kind.INKY:
			var p := pac_tile + pac_dir * 2
			if pac_dir == PM.UP:
				p += PM.LEFT * 2
			var b: Vector2i = game.ghosts[Kind.BLINKY].tile
			return p + (p - b)
		_:
			if Vector2(tile - pac_tile).length() > 8.0:
				return pac_tile
			return scatter_tile

func _make_flash_texture(src: Texture2D) -> Texture2D:
	var img: Image = src.get_image()
	if img == null:
		return src
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.2:
				continue
			if c.r > 0.6 and c.g > 0.6 and c.b > 0.6:
				img.set_pixel(x, y, PM.C_RED)
			else:
				img.set_pixel(x, y, PM.C_WALL_FLASH)
	return ImageTexture.create_from_image(img)

func _refresh_sprite() -> void:
	if eaten:
		sprite.visible = false
		queue_redraw()
		return
	sprite.visible = true
	if frightened:
		sprite.texture = fright_flash_tex if (flashing and flash_on) else fright_tex
	else:
		sprite.texture = body_tex
	queue_redraw()

func _draw() -> void:
	if not eaten:
		return
	var look := Vector2(dir)
	var k := PM.SPRITE_SCALE
	for sx in [-1.0, 1.0]:
		var c := Vector2(sx * 3.0 * k, -1.5 * k)
		draw_rect(Rect2(c - Vector2(2.0, 2.5) * k, Vector2(4, 5) * k), PM.C_TEXT)
		draw_rect(Rect2(c + look * 1.5 * k - Vector2(1, 1) * k, Vector2(2, 2) * k), Color("2121de"))
