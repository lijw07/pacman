class_name Hud
extends Node2D

const GHOST_NAMES := ["BLINKY", "PINKY", "INKY", "CLYDE"]
const GHOST_TRAITS := ["CHASER", "AMBUSHER", "FLANKER", "LONER"]
const MENU_LABELS := ["CONTINUE", "QUIT"]

var game = null
var life_tex: Texture2D
var pac_tex: Texture2D
var ghost_tex: Array[Texture2D] = []
var fruit_tex := {}

func _ready() -> void:
	life_tex = load("res://pacman-art/pacman-left/1.png")
	pac_tex = load("res://pacman-art/pacman-right/1.png")
	for n in ["blinky", "pinky", "inky", "clyde"]:
		ghost_tex.append(load("res://pacman-art/ghosts/%s.png" % n))
	fruit_tex["strawberry"] = load("res://pacman-art/other/strawberry.png")
	fruit_tex["apple"] = load("res://pacman-art/other/apple.png")
	z_index = 20

func _process(_delta: float) -> void:
	if game != null and (game.state == PM.ST_TITLE or game.state == PM.ST_LEVEL_MENU):
		queue_redraw()

func _draw() -> void:
	if game == null:
		return
	if game.state == PM.ST_TITLE:
		_draw_title()
	else:
		_draw_play()
		if game.state == PM.ST_LEVEL_MENU:
			_draw_level_menu()
	if game.debug_enabled and game.debug_open:
		_draw_debug_panel()

func _draw_play() -> void:
	PxFont.draw_text(self, "1UP", Vector2(3 * PM.TILE, 4), 2, PM.C_TEXT)
	PxFont.draw_centered(self, "HIGH SCORE", PM.CENTER_X, 4.0, 2, PM.C_TEXT)
	_draw_number(game.score, 7 * PM.TILE + 8, 22.0)
	_draw_number(game.high_score, 17 * PM.TILE + 8, 22.0)

	var by := float((PM.ROWS + PM.HUD_TOP_ROWS) * PM.TILE) + 1.0
	for i in maxi(game.lives, 0):
		draw_texture_rect(life_tex, Rect2(Vector2(24 + i * 32, by), Vector2(30, 30)), false)
	var shown: Array = game.fruit_history
	for i in shown.size():
		var fname: String = shown[shown.size() - 1 - i]
		var tex: Texture2D = fruit_tex.get(fname, null)
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2(396 - i * 32, by), Vector2(30, 30)), false)

	PxFont.draw_centered(self, "LEVEL %d" % game.level, PM.CENTER_X, by + 9.0, 1, PM.C_PELLET)

	var msg_y := PM.ORIGIN.y + 17.0 * PM.TILE + 3.0
	var st: int = game.state
	if st == PM.ST_READY:
		PxFont.draw_centered(self, "READY!", PM.CENTER_X, msg_y, 2, PM.C_YELLOW)
	elif st == PM.ST_GAME_OVER:
		PxFont.draw_centered(self, "GAME OVER", PM.CENTER_X, msg_y, 2, PM.C_RED)
	if st == PM.ST_READY and game.show_player_one:
		PxFont.draw_centered(self, "PLAYER ONE", PM.CENTER_X, PM.ORIGIN.y + 11.0 * PM.TILE + 3.0, 2, PM.C_CYAN)

	for p in game.popups:
		PxFont.draw_centered(self, str(p["text"]), p["pos"].x, p["pos"].y - 6.0, 1, p["color"])

func _draw_debug_panel() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(PM.VIEW_SIZE)), Color(0.0, 0.0, 0.0, 0.84))
	var panel: Rect2 = game.DEBUG_PANEL_RECT
	draw_rect(panel, PM.C_BG)
	draw_rect(panel, PM.C_CYAN, false, 2.0)
	PxFont.draw_centered(self, "DEBUG", PM.CENTER_X, panel.position.y + 10.0, 3, PM.C_CYAN)

	var d := PM.level_data(game.level)
	PxFont.draw_centered(self, "LEVEL %d    SEED %d" % [game.level, game.maze_seed()],
		PM.CENTER_X, 136.0, 1, PM.C_YELLOW)
	PxFont.draw_centered(self, "DOTS %d    REMAINING %d" % [game.board.total_pellets,
		game.board.pellets_left()], PM.CENTER_X, 150.0, 1, PM.C_TEXT)
	PxFont.draw_centered(self, "GHOST %.2f   PAC %.2f   FRIGHT %.1fS" % [float(d["ghost"]),
		float(d["pac"]), float(d["fright"])], PM.CENTER_X, 164.0, 1, PM.C_TEXT)

	for b in game.debug_buttons():
		var r: Rect2 = b["rect"]
		var on: bool = b["on"]
		draw_rect(r, Color(0.16, 0.30, 0.30) if on else Color(0.09, 0.09, 0.12))
		draw_rect(r, PM.C_YELLOW if on else PM.C_CYAN, false, 1.0)
		PxFont.draw_centered(self, str(b["label"]), r.position.x + r.size.x * 0.5,
			r.position.y + 11.0, 2, PM.C_YELLOW if on else PM.C_TEXT)

	PxFont.draw_centered(self, "F1 PANEL  N NEXT  B BACK  R NEW MAZE  C CLEAR  I INVUL  G FREEZE",
		PM.CENTER_X, 350.0, 1, PM.C_PELLET)
	PxFont.draw_centered(self, "LEVEL 1 IS THE ARCADE BOARD. EVERY LEVEL AFTER IS GENERATED.",
		PM.CENTER_X, 364.0, 1, PM.C_PELLET)

func _draw_level_menu() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(PM.VIEW_SIZE)), Color(0.0, 0.0, 0.0, 0.74))
	var panel := Rect2(54.0, 170.0, 340.0, 236.0)
	draw_rect(panel, PM.C_BG)
	draw_rect(panel, game.board.wall_color, false, 2.0)
	PxFont.draw_centered(self, "LEVEL %d" % game.level, PM.CENTER_X, 196.0, 3, PM.C_YELLOW)
	PxFont.draw_centered(self, "COMPLETE", PM.CENTER_X, 228.0, 3, PM.C_YELLOW)
	PxFont.draw_centered(self, "SCORE %d" % game.score, PM.CENTER_X, 264.0, 2, PM.C_TEXT)
	for i in MENU_LABELS.size():
		var r: Rect2 = game.menu_rect(i)
		var selected: bool = game.menu_index == i
		if selected:
			draw_rect(r, Color(1.0, 1.0, 1.0, 0.12))
			draw_texture_rect(pac_tex, Rect2(r.position + Vector2(6.0, 4.0), Vector2(26, 26)), false)
		PxFont.draw_centered(self, MENU_LABELS[i], r.position.x + r.size.x * 0.5 + 12.0,
			r.position.y + 11.0, 2, PM.C_YELLOW if selected else PM.C_TEXT)
	PxFont.draw_centered(self, "ARROWS TO CHOOSE  -  ENTER OR TAP", PM.CENTER_X, 384.0, 1, PM.C_CYAN)

func _draw_title() -> void:
	var blink := int(Time.get_ticks_msec() / 400.0) % 2 == 0
	PxFont.draw_centered(self, "PAC-MAN", PM.CENTER_X, 70.0, 7, PM.C_YELLOW)
	PxFont.draw_centered(self, "HIGH SCORE", PM.CENTER_X, 150.0, 2, PM.C_TEXT)
	PxFont.draw_centered(self, str(maxi(game.high_score, 0)), PM.CENTER_X, 176.0, 3, PM.C_PELLET)

	var y := 250.0
	for i in 4:
		var x := 56.0 + float(i) * 112.0
		draw_texture_rect(ghost_tex[i], Rect2(Vector2(x - 16, y - 16), Vector2(32, 32)), false)
		PxFont.draw_centered(self, GHOST_NAMES[i], x, y + 24.0, 1, Ghost.kind_color(i))
		PxFont.draw_centered(self, GHOST_TRAITS[i], x, y + 38.0, 1, PM.C_TEXT)

	draw_texture_rect(pac_tex, Rect2(Vector2(PM.CENTER_X - 20, 330.0), Vector2(40, 40)), false)

	if blink:
		PxFont.draw_centered(self, "PRESS ENTER TO START", PM.CENTER_X, 400.0, 2, PM.C_TEXT)
	PxFont.draw_centered(self, "ARROW KEYS OR WASD TO MOVE", PM.CENTER_X, 450.0, 1, PM.C_CYAN)
	PxFont.draw_centered(self, "OR SWIPE ON A TOUCH SCREEN", PM.CENTER_X, 466.0, 1, PM.C_CYAN)
	PxFont.draw_centered(self, "ENDLESS MAZES  -  ARCADE GHOST AI", PM.CENTER_X, 510.0, 1, PM.C_PELLET)

func _draw_number(value: int, right_x: float, y: float) -> void:
	var s := str(maxi(value, 0))
	if value <= 0:
		s = "00"
	var w := PxFont.text_width(s, 2)
	PxFont.draw_text(self, s, Vector2(right_x - w, y), 2, PM.C_TEXT)
