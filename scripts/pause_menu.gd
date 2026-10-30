class_name PauseMenu
extends Node2D

signal resume_requested
signal restart_requested
signal main_menu_requested
signal settings_changed

enum Page { MAIN, SETTINGS }

const MAIN_ITEMS := ["RESUME", "RESTART", "SETTINGS", "MAIN MENU"]
const SETTINGS_ITEMS := ["MASTER", "EFFECTS", "SIREN", "BACK"]
const VOLUME_BUSES := [Sfx.BUS_MASTER, Sfx.BUS_EFFECTS, Sfx.BUS_SIREN]
const MAIN_RESUME := 0
const MAIN_RESTART := 1
const MAIN_SETTINGS := 2
const MAIN_MENU := 3
const PANEL := Rect2(54.0, 150.0, 340.0, 290.0)
const ROW_SIZE := Vector2(260.0, 34.0)
const ROW_TOP := 222.0
const ROW_GAP := 44.0
const SEGMENT_PITCH := 10.0
const SEGMENT_SIZE := Vector2(8.0, 16.0)
const TAP_SLOP := 24.0

var sfx: Sfx
var frame_color := PM.C_FRIGHT
var page := Page.MAIN
var index := 0
var press_origin := Vector2.ZERO
var pressing := false
var pac_tex: Texture2D

func _ready() -> void:
	pac_tex = load("res://pacman-art/pacman-right/1.png")
	z_index = 30
	visible = false

func open(color: Color) -> void:
	frame_color = color
	page = Page.MAIN
	index = MAIN_RESUME
	pressing = false
	visible = true
	queue_redraw()

func close() -> void:
	visible = false

func items() -> Array:
	return MAIN_ITEMS if page == Page.MAIN else SETTINGS_ITEMS

func row_rect(i: int) -> Rect2:
	return Rect2(Vector2(PM.CENTER_X - ROW_SIZE.x * 0.5, ROW_TOP + float(i) * ROW_GAP), ROW_SIZE)

func bar_rect(i: int) -> Rect2:
	var r := row_rect(i)
	var width := SEGMENT_PITCH * Sfx.VOLUME_STEPS - (SEGMENT_PITCH - SEGMENT_SIZE.x)
	return Rect2(Vector2(r.end.x - 10.0 - width, r.position.y + (r.size.y - SEGMENT_SIZE.y) * 0.5),
		Vector2(width, SEGMENT_SIZE.y))

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("pm_pause"):
		_back()
	elif event.is_action_pressed("pm_up", true):
		_move(-1)
	elif event.is_action_pressed("pm_down", true):
		_move(1)
	elif event.is_action_pressed("pm_left", true):
		_adjust(-1)
	elif event.is_action_pressed("pm_right", true):
		_adjust(1)
	elif event.is_action_pressed("pm_start"):
		_activate()
	elif event is InputEventMouseMotion:
		_hover(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(event.pressed, event.position)
	elif event is InputEventScreenTouch:
		_pointer(event.pressed, event.position)
	queue_redraw()

func _move(step: int) -> void:
	index = wrapi(index + step, 0, items().size())
	sfx.play_ui("ui_move")

func _hover(pos: Vector2) -> void:
	var hit := _row_at(pos)
	if hit >= 0 and hit != index:
		index = hit
		sfx.play_ui("ui_move")

func _pointer(pressed: bool, pos: Vector2) -> void:
	if pressed:
		press_origin = pos
		pressing = true
		return
	if not pressing:
		return
	pressing = false
	if (pos - press_origin).length() >= TAP_SLOP:
		return
	var hit := _row_at(pos)
	if hit < 0:
		return
	index = hit
	if _is_volume_row(hit):
		_set_volume(hit, _step_at(hit, pos.x))
	else:
		_activate()

func _row_at(pos: Vector2) -> int:
	for i in items().size():
		if row_rect(i).has_point(pos):
			return i
	return -1

func _step_at(i: int, x: float) -> int:
	var bar := bar_rect(i)
	var current := sfx.level(VOLUME_BUSES[i])
	if x < bar.position.x:
		return current
	var tapped := int((x - bar.position.x) / SEGMENT_PITCH) + 1
	return tapped - 1 if tapped == current else tapped

func _is_volume_row(i: int) -> bool:
	return page == Page.SETTINGS and i < VOLUME_BUSES.size()

func _adjust(step: int) -> void:
	if _is_volume_row(index):
		_set_volume(index, sfx.level(VOLUME_BUSES[index]) + step)

func _set_volume(i: int, step: int) -> void:
	var bus: String = VOLUME_BUSES[i]
	if sfx.set_level(bus, step):
		sfx.play_ui("ui_move", bus)
		settings_changed.emit()

func _activate() -> void:
	if page == Page.SETTINGS:
		if not _is_volume_row(index):
			_back()
		return
	sfx.play_ui("ui_select")
	match index:
		MAIN_RESUME:
			resume_requested.emit()
		MAIN_RESTART:
			restart_requested.emit()
		MAIN_SETTINGS:
			page = Page.SETTINGS
			index = 0
		MAIN_MENU:
			main_menu_requested.emit()

func _back() -> void:
	sfx.play_ui("ui_back")
	if page == Page.SETTINGS:
		page = Page.MAIN
		index = MAIN_SETTINGS
	else:
		resume_requested.emit()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(PM.VIEW_SIZE)), Color(0.0, 0.0, 0.0, 0.74))
	draw_rect(PANEL, PM.C_BG)
	draw_rect(PANEL, frame_color, false, 2.0)
	var title := "PAUSED" if page == Page.MAIN else "SETTINGS"
	PxFont.draw_centered(self, title, PM.CENTER_X, PANEL.position.y + 24.0, 3, PM.C_YELLOW)
	for i in items().size():
		_draw_row(i)
	var hint := "ARROWS TO CHOOSE  -  ENTER OR TAP"
	if page == Page.SETTINGS:
		hint = "LEFT RIGHT TO CHANGE  -  ESC TO GO BACK"
	PxFont.draw_centered(self, hint, PM.CENTER_X, PANEL.end.y - 22.0, 1, PM.C_CYAN)

func _draw_row(i: int) -> void:
	var r := row_rect(i)
	var selected := i == index
	var color := PM.C_YELLOW if selected else PM.C_TEXT
	if selected:
		draw_rect(r, Color(1.0, 1.0, 1.0, 0.12))
		draw_texture_rect(pac_tex, Rect2(r.position + Vector2(6.0, 4.0), Vector2(26, 26)), false)
	var label: String = items()[i]
	var text_y := r.position.y + 11.0
	if _is_volume_row(i):
		PxFont.draw_text(self, label, Vector2(r.position.x + 40.0, text_y), 2, color)
		_draw_volume_bar(bar_rect(i), sfx.level(VOLUME_BUSES[i]), color)
	else:
		PxFont.draw_centered(self, label, r.position.x + r.size.x * 0.5 + 12.0, text_y, 2, color)

func _draw_volume_bar(bar: Rect2, filled: int, color: Color) -> void:
	for s in Sfx.VOLUME_STEPS:
		var seg := Rect2(bar.position + Vector2(float(s) * SEGMENT_PITCH, 0.0), SEGMENT_SIZE)
		if s < filled:
			draw_rect(seg, color)
		else:
			draw_rect(seg, Color(color, 0.3), false, 1.0)
