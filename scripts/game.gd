extends Node2D

const SAVE_PATH := "user://pacman_save.cfg"
const EXTRA_LIFE_AT := 10000
const READY_TIME := 2.2
const READY_TIME_SHORT := 1.6
const GHOST_EAT_PAUSE := 0.9
const FRUIT_DURATION := 9.5
const GHOST_SCORES := [200, 400, 800, 1600]
const MENU_OPTIONS := ["CONTINUE", "QUIT"]
const DEBUG_PANEL_RECT := Rect2(22.0, 96.0, 404.0, 336.0)

var board: Board
var player: Player
var ghosts: Array[Ghost] = []
var hud: Hud
var sfx: Sfx
var fruit_sprite: Sprite2D

var state := PM.ST_READY
var state_timer := 0.0
var show_player_one := true

var score := 0
var high_score := 0
var lives := 3
var level := 1
var extra_life_given := false

var chase_mode := false
var wave_index := 0
var wave_timer := 0.0
var waves: Array = []

var fright_active := false
var fright_timer := 0.0
var fright_flash_timer := 0.0
var fright_chain := 0

var dots_eaten_this_life := 0
var release_timer := 0.0
var waka_toggle := false

var fruit_active := false
var fruit_timer := 0.0
var fruit_spawned := 0
var fruit_history: Array = []

var popups: Array = []
var eaten_ghost: Ghost = null
var level_data := {}

var start_requested := false
var menu_index := 0
var run_seed := 0
var debug_enabled := OS.is_debug_build()
var debug_open := false
var invincible := false
var ghosts_frozen := false
var touch_origin := Vector2.ZERO
var touch_active := false

func _ready() -> void:
	randomize()
	run_seed = randi() & 0x0FFFFFFF
	_register_input()
	_load_save()
	board = Board.new()
	add_child(board)
	board.build(PM.MAZE_CLASSIC, PM.level_color(1))
	sfx = Sfx.new()
	add_child(sfx)
	fruit_sprite = Sprite2D.new()
	fruit_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fruit_sprite.scale = Vector2(2, 2)
	fruit_sprite.visible = false
	fruit_sprite.z_index = 5
	add_child(fruit_sprite)
	player = Player.new()
	player.board = board
	player.z_index = 10
	add_child(player)
	for k in 4:
		var g := Ghost.new()
		g.setup(k)
		g.board = board
		g.game = self
		g.z_index = 11
		add_child(g)
		ghosts.append(g)
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	enter_title()

func _on_viewport_resized() -> void:
	hud.queue_redraw()

func enter_title() -> void:
	sfx.stop_loop()
	level = 1
	score = 0
	lives = 3
	extra_life_given = false
	fruit_history.clear()
	level_data = PM.level_data(1)
	_build_maze()
	_reset_actors()
	show_world(false)
	start_requested = false
	_set_state(PM.ST_TITLE)

func show_world(on: bool) -> void:
	board.visible = on
	player.visible = on
	fruit_sprite.visible = on and fruit_active
	for g in ghosts:
		g.visible = on

func _register_input() -> void:
	var map := {
		"pm_up": [KEY_UP, KEY_W],
		"pm_down": [KEY_DOWN, KEY_S],
		"pm_left": [KEY_LEFT, KEY_A],
		"pm_right": [KEY_RIGHT, KEY_D],
		"pm_start": [KEY_ENTER, KEY_SPACE],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func debug_buttons() -> Array:
	var out: Array = []
	out.append({"id": "level_down", "label": "LEVEL -", "rect": Rect2(34.0, 178.0, 122.0, 30.0), "on": false})
	out.append({"id": "level_up", "label": "LEVEL +", "rect": Rect2(164.0, 178.0, 122.0, 30.0), "on": false})
	out.append({"id": "level_jump", "label": "LEVEL +5", "rect": Rect2(294.0, 178.0, 122.0, 30.0), "on": false})
	out.append({"id": "reroll", "label": "NEW MAZE", "rect": Rect2(34.0, 220.0, 186.0, 30.0), "on": false})
	out.append({"id": "restart", "label": "RESTART", "rect": Rect2(230.0, 220.0, 186.0, 30.0), "on": false})
	out.append({"id": "clear", "label": "CLEAR LEVEL", "rect": Rect2(34.0, 262.0, 186.0, 30.0), "on": false})
	out.append({"id": "fright", "label": "ENERGIZER", "rect": Rect2(230.0, 262.0, 186.0, 30.0), "on": fright_active})
	out.append({"id": "invincible", "label": "INVINCIBLE", "rect": Rect2(34.0, 304.0, 186.0, 30.0), "on": invincible})
	out.append({"id": "freeze", "label": "FREEZE GHOSTS", "rect": Rect2(230.0, 304.0, 186.0, 30.0), "on": ghosts_frozen})
	out.append({"id": "close", "label": "CLOSE", "rect": Rect2(150.0, 386.0, 148.0, 30.0), "on": false})
	return out

func debug_press(id: String) -> void:
	if id == "close":
		debug_open = false
		return
	if id == "invincible":
		invincible = not invincible
		return
	if id == "freeze":
		ghosts_frozen = not ghosts_frozen
		return
	if id == "fright":
		if state == PM.ST_PLAY:
			_start_fright()
			debug_open = false
		return
	if id == "clear":
		if state == PM.ST_PLAY:
			_finish_level()
			debug_open = false
		return
	if id == "restart":
		start_level(true)
		debug_open = false
		return
	if id == "level_up":
		level += 1
	elif id == "level_jump":
		level += 5
	elif id == "level_down":
		level = maxi(1, level - 1)
	elif id == "reroll":
		run_seed = randi() & 0x0FFFFFFF
		if level == 1:
			level = 2
	else:
		return
	lives = maxi(lives, 1)
	start_level(true)
	debug_open = false

func _debug_key(event: InputEvent) -> bool:
	if not debug_enabled or not (event is InputEventKey) or not event.pressed or event.echo:
		return false
	match event.keycode:
		KEY_F1:
			debug_open = not debug_open
		KEY_N:
			debug_press("level_up")
		KEY_B:
			debug_press("level_down")
		KEY_C:
			debug_press("clear")
		KEY_I:
			debug_press("invincible")
		KEY_G:
			debug_press("freeze")
		KEY_R:
			debug_press("reroll")
		_:
			return false
	return true

func menu_rect(i: int) -> Rect2:
	return Rect2(PM.CENTER_X - 92.0, 292.0 + float(i) * 44.0, 184.0, 34.0)

func _unhandled_input(event: InputEvent) -> void:
	if _debug_key(event):
		return
	if debug_open:
		if event is InputEventScreenTouch:
			_handle_pointer(event.pressed, event.position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_pointer(event.pressed, event.position)
		return
	if state == PM.ST_LEVEL_MENU:
		if event.is_action_pressed("pm_up") or event.is_action_pressed("pm_left"):
			menu_index = wrapi(menu_index - 1, 0, MENU_OPTIONS.size())
			return
		if event.is_action_pressed("pm_down") or event.is_action_pressed("pm_right"):
			menu_index = wrapi(menu_index + 1, 0, MENU_OPTIONS.size())
			return
		if event is InputEventMouseMotion:
			for i in MENU_OPTIONS.size():
				if menu_rect(i).has_point(event.position):
					menu_index = i
			return
	if event.is_action_pressed("pm_start"):
		start_requested = true
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.pressed, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.pressed, event.position)

func _handle_pointer(pressed: bool, pos: Vector2) -> void:
	if pressed:
		touch_origin = pos
		touch_active = true
		return
	if not touch_active:
		return
	touch_active = false
	var tap := (pos - touch_origin).length() < 24.0
	if debug_open:
		if tap:
			for b in debug_buttons():
				if (b["rect"] as Rect2).has_point(pos):
					debug_press(b["id"])
					return
		return
	if state == PM.ST_LEVEL_MENU:
		for i in MENU_OPTIONS.size():
			if menu_rect(i).has_point(pos):
				menu_index = i
				start_requested = true
		return
	var delta := pos - touch_origin
	if delta.length() < 24.0:
		start_requested = true
		return
	if absf(delta.x) > absf(delta.y):
		player.wanted = PM.RIGHT if delta.x > 0.0 else PM.LEFT
	else:
		player.wanted = PM.DOWN if delta.y > 0.0 else PM.UP

func start_level(fresh: bool) -> void:
	level_data = PM.level_data(level)
	waves = PM.wave_table(level)
	wave_index = 0
	wave_timer = 0.0
	chase_mode = false
	if fresh:
		_build_maze()
		fruit_spawned = 0
		dots_eaten_this_life = 0
	board.flash_white = false
	board.queue_redraw()
	_reset_actors()
	show_world(true)
	show_player_one = fresh and lives == 3 and level == 1
	_set_state(PM.ST_READY)
	sfx.stop_loop()
	sfx.play("ready")

func maze_seed() -> int:
	return run_seed + level * 7919

func _build_maze() -> void:
	var rows: Array = PM.MAZE_CLASSIC
	if level > 1:
		rows = MazeGen.generate(maze_seed())
	board.build(rows, PM.level_color(level))

func _reset_actors() -> void:
	fright_active = false
	fright_timer = 0.0
	fright_chain = 0
	release_timer = 0.0
	popups.clear()
	eaten_ghost = null
	fruit_active = false
	fruit_sprite.visible = false
	player.reset(float(level_data["pac"]))
	var limits := _house_limits()
	for i in ghosts.size():
		var g := ghosts[i]
		g.apply_level(level_data)
		g.reset_position()
		g.dot_limit = limits[i]
	_update_elroy()

func _house_limits() -> Array:
	if level == 1:
		return [0, 0, 30, 60]
	elif level == 2:
		return [0, 0, 0, 50]
	return [0, 0, 0, 0]

func _set_state(s: int) -> void:
	state = s
	state_timer = 0.0
	if s == PM.ST_GAME_OVER or s == PM.ST_LEVEL_CLEAR:
		_save()
	hud.queue_redraw()

func _process(delta: float) -> void:
	if debug_open:
		hud.queue_redraw()
		return
	match state:
		PM.ST_TITLE:
			_tick_title(delta)
		PM.ST_LEVEL_MENU:
			_tick_level_menu(delta)
		PM.ST_READY:
			_tick_ready(delta)
		PM.ST_PLAY:
			_tick_play(delta)
		PM.ST_GHOST_EATEN:
			_tick_ghost_eaten(delta)
		PM.ST_DYING:
			_tick_dying(delta)
		PM.ST_LEVEL_CLEAR:
			_tick_level_clear(delta)
		PM.ST_GAME_OVER:
			_tick_game_over(delta)
	hud.queue_redraw()

func _tick_title(delta: float) -> void:
	state_timer += delta
	if start_requested and state_timer > 0.3:
		start_requested = false
		_restart()

func _tick_ready(delta: float) -> void:
	state_timer += delta
	var limit := READY_TIME if show_player_one else READY_TIME_SHORT
	if state_timer >= limit:
		show_player_one = false
		player.frozen = false
		_set_state(PM.ST_PLAY)

func _tick_play(delta: float) -> void:
	player.tick(delta)
	_update_waves(delta)
	_update_fright(delta)
	_update_release(delta)
	if not ghosts_frozen:
		for g in ghosts:
			g.tick(delta)
	_check_pellet()
	_update_fruit(delta)
	_check_collisions()
	_update_audio()
	_update_popups(delta)
	if board.pellets_left() == 0:
		_finish_level()

func _tick_ghost_eaten(delta: float) -> void:
	state_timer += delta
	_update_popups(delta)
	if state_timer >= GHOST_EAT_PAUSE:
		player.visible = true
		for g in ghosts:
			g.visible = true
		popups.clear()
		_set_state(PM.ST_PLAY)

func _tick_dying(delta: float) -> void:
	state_timer += delta
	player.tick(delta)
	if state_timer > 0.6:
		for g in ghosts:
			g.visible = false
	if player.death_finished():
		lives -= 1
		if lives <= 0:
			_set_state(PM.ST_GAME_OVER)
		else:
			dots_eaten_this_life = 0
			start_level(false)

func _tick_level_clear(delta: float) -> void:
	state_timer += delta
	board.flash_white = int(state_timer / 0.22) % 2 == 1 and state_timer > 0.6
	board.queue_redraw()
	if state_timer >= 3.0:
		board.flash_white = false
		board.queue_redraw()
		menu_index = 0
		start_requested = false
		_set_state(PM.ST_LEVEL_MENU)

func _tick_level_menu(delta: float) -> void:
	state_timer += delta
	if not start_requested or state_timer < 0.3:
		return
	start_requested = false
	if menu_index == 0:
		level += 1
		start_level(true)
	else:
		enter_title()

func _tick_game_over(delta: float) -> void:
	state_timer += delta
	if state_timer >= 2.0 and (start_requested or state_timer >= 6.0):
		start_requested = false
		enter_title()

func _restart() -> void:
	score = 0
	lives = 3
	level = 1
	extra_life_given = false
	fruit_history.clear()
	start_level(true)

func maze_color() -> Color:
	return board.wall_color

func _update_waves(delta: float) -> void:
	if fright_active or wave_index >= waves.size():
		return
	var span: float = waves[wave_index]
	if span < 0.0:
		return
	wave_timer += delta
	if wave_timer >= span:
		wave_timer = 0.0
		wave_index += 1
		chase_mode = wave_index % 2 == 1
		for g in ghosts:
			if not g.eaten:
				g.reverse_safe()

func _update_fright(delta: float) -> void:
	if not fright_active:
		return
	fright_timer -= delta
	var flash_start: float = minf(2.0, float(level_data["fright"]) * 0.4)
	if fright_timer <= flash_start:
		fright_flash_timer += delta
		if fright_flash_timer >= 0.18:
			fright_flash_timer = 0.0
			for g in ghosts:
				g.flashing = true
				g.flash_on = not g.flash_on
	if fright_timer <= 0.0:
		_end_fright()

func _end_fright() -> void:
	fright_active = false
	fright_chain = 0
	player.speed = PM.BASE_SPEED * float(level_data["pac"])
	for g in ghosts:
		g.flashing = false
		g.flash_on = false
		g.set_frightened(false)

func _start_fright() -> void:
	var duration := float(level_data["fright"])
	fright_chain = 0
	if duration <= 0.0:
		for g in ghosts:
			if not g.eaten:
				g.reverse_safe()
		return
	fright_active = true
	fright_timer = duration
	fright_flash_timer = 0.0
	player.speed = PM.BASE_SPEED * float(level_data["pac_fright"])
	for g in ghosts:
		g.flashing = false
		g.flash_on = false
		g.set_frightened(true)

func _update_release(delta: float) -> void:
	release_timer += delta
	var limit := 4.0 if level < 5 else 3.0
	for i in [Ghost.Kind.PINKY, Ghost.Kind.INKY, Ghost.Kind.CLYDE]:
		var g: Ghost = ghosts[i]
		if g.state == Ghost.St.HOUSE:
			if dots_eaten_this_life >= g.dot_limit or release_timer >= limit:
				g.release()
				release_timer = 0.0
			return

func request_release(g: Ghost) -> void:
	g.dot_limit = 0
	g.release()

func _check_pellet() -> void:
	var kind := board.eat(player.tile)
	if kind == 0:
		return
	dots_eaten_this_life += 1
	release_timer = 0.0
	if kind == 1:
		_add_score(10)
		waka_toggle = not waka_toggle
		sfx.play("waka_a" if waka_toggle else "waka_b")
	else:
		_add_score(50)
		sfx.play("pellet")
		_start_fright()
	_update_elroy()
	var eaten_count := board.total_pellets - board.pellets_left()
	if (eaten_count == 70 or eaten_count == 170) and fruit_spawned < 2:
		_spawn_fruit()

func _update_elroy() -> void:
	var left := board.pellets_left()
	var b: Ghost = ghosts[Ghost.Kind.BLINKY]
	if left <= int(level_data["elroy2"]):
		b.elroy = 2
	elif left <= int(level_data["elroy1"]):
		b.elroy = 1
	else:
		b.elroy = 0

func _spawn_fruit() -> void:
	fruit_spawned += 1
	var f := PM.fruit_for_level(level)
	fruit_sprite.texture = load("res://pacman-art/other/%s.png" % f["tex"])
	fruit_sprite.position = PM.tile_center_f(PM.FRUIT_TILE)
	fruit_sprite.visible = true
	fruit_active = true
	fruit_timer = FRUIT_DURATION

func _update_fruit(delta: float) -> void:
	if not fruit_active:
		return
	fruit_timer -= delta
	if fruit_timer <= 0.0:
		fruit_active = false
		fruit_sprite.visible = false
		return
	if player.position.distance_to(fruit_sprite.position) < 14.0:
		var f := PM.fruit_for_level(level)
		_add_score(int(f["points"]))
		_add_popup(str(f["points"]), fruit_sprite.position, PM.C_PELLET, 1.8)
		fruit_active = false
		fruit_sprite.visible = false
		sfx.play("fruit")
		fruit_history.append(f["tex"])
		if fruit_history.size() > 7:
			fruit_history.pop_front()

func _check_collisions() -> void:
	for g in ghosts:
		if g.state == Ghost.St.HOUSE or g.state == Ghost.St.ENTERING or g.eaten:
			continue
		if player.position.distance_to(g.position) > 11.0:
			continue
		if g.frightened:
			_eat_ghost(g)
			return
		if invincible:
			continue
		_kill_player()
		return

func _eat_ghost(g: Ghost) -> void:
	var points: int = GHOST_SCORES[mini(fright_chain, GHOST_SCORES.size() - 1)]
	fright_chain += 1
	_add_score(points)
	g.eaten = true
	g.frightened = false
	g.flashing = false
	g._refresh_sprite()
	eaten_ghost = g
	sfx.play("ghost")
	popups.clear()
	_add_popup(str(points), g.position, PM.C_CYAN, GHOST_EAT_PAUSE)
	player.visible = false
	for other in ghosts:
		if other != g:
			other.visible = false
	_set_state(PM.ST_GHOST_EATEN)

func _kill_player() -> void:
	sfx.stop_loop()
	sfx.play("death")
	player.start_death()
	_set_state(PM.ST_DYING)

func _finish_level() -> void:
	sfx.stop_loop()
	player.frozen = true
	for g in ghosts:
		g.visible = false
	_set_state(PM.ST_LEVEL_CLEAR)

func _add_score(points: int) -> void:
	score += points
	if not extra_life_given and score >= EXTRA_LIFE_AT:
		extra_life_given = true
		lives += 1
		sfx.play("extra")
	if score > high_score:
		high_score = score

func _add_popup(text: String, pos: Vector2, color: Color, life: float) -> void:
	popups.append({"text": text, "pos": pos, "color": color, "life": life})

func _update_popups(delta: float) -> void:
	for i in range(popups.size() - 1, -1, -1):
		popups[i]["life"] -= delta
		if popups[i]["life"] <= 0.0:
			popups.remove_at(i)

func _update_audio() -> void:
	var returning := false
	for g in ghosts:
		if g.eaten or g.state == Ghost.St.ENTERING:
			returning = true
	if returning:
		sfx.play_loop("retreat")
	elif fright_active:
		sfx.play_loop("fright")
	else:
		sfx.play_loop("siren")

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = int(cfg.get_value("game", "high_score", 0))

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "high_score", high_score)
	cfg.save(SAVE_PATH)
