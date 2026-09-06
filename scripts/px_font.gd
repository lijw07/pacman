class_name PxFont
extends RefCounted

const W := 5
const H := 7

const GLYPHS := {
	" ": [".....", ".....", ".....", ".....", ".....", ".....", "....."],
	"0": [".XXX.", "X...X", "X..XX", "X.X.X", "XX..X", "X...X", ".XXX."],
	"1": ["..X..", ".XX..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
	"2": [".XXX.", "X...X", "....X", "...X.", "..X..", ".X...", "XXXXX"],
	"3": ["XXXXX", "...X.", "..XX.", "....X", "....X", "X...X", ".XXX."],
	"4": ["...X.", "..XX.", ".X.X.", "X..X.", "XXXXX", "...X.", "...X."],
	"5": ["XXXXX", "X....", "XXXX.", "....X", "....X", "X...X", ".XXX."],
	"6": ["..XX.", ".X...", "X....", "XXXX.", "X...X", "X...X", ".XXX."],
	"7": ["XXXXX", "....X", "...X.", "..X..", ".X...", ".X...", ".X..."],
	"8": [".XXX.", "X...X", "X...X", ".XXX.", "X...X", "X...X", ".XXX."],
	"9": [".XXX.", "X...X", "X...X", ".XXXX", "....X", "...X.", ".XX.."],
	"A": [".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
	"B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
	"C": [".XXX.", "X...X", "X....", "X....", "X....", "X...X", ".XXX."],
	"D": ["XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX."],
	"E": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX"],
	"F": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "X...."],
	"G": [".XXX.", "X...X", "X....", "X..XX", "X...X", "X...X", ".XXXX"],
	"H": ["X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
	"I": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "XXXXX"],
	"J": ["..XXX", "...X.", "...X.", "...X.", "...X.", "X..X.", ".XX.."],
	"K": ["X...X", "X..X.", "X.X..", "XX...", "X.X..", "X..X.", "X...X"],
	"L": ["X....", "X....", "X....", "X....", "X....", "X....", "XXXXX"],
	"M": ["X...X", "XX.XX", "X.X.X", "X.X.X", "X...X", "X...X", "X...X"],
	"N": ["X...X", "XX..X", "XX..X", "X.X.X", "X..XX", "X..XX", "X...X"],
	"O": [".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
	"P": ["XXXX.", "X...X", "X...X", "XXXX.", "X....", "X....", "X...."],
	"Q": [".XXX.", "X...X", "X...X", "X...X", "X.X.X", "X..X.", ".XX.X"],
	"R": ["XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X"],
	"S": [".XXXX", "X....", "X....", ".XXX.", "....X", "....X", "XXXX."],
	"T": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.."],
	"U": ["X...X", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
	"V": ["X...X", "X...X", "X...X", "X...X", "X...X", ".X.X.", "..X.."],
	"W": ["X...X", "X...X", "X...X", "X.X.X", "X.X.X", "XX.XX", "X...X"],
	"X": ["X...X", "X...X", ".X.X.", "..X..", ".X.X.", "X...X", "X...X"],
	"Y": ["X...X", "X...X", ".X.X.", "..X..", "..X..", "..X..", "..X.."],
	"Z": ["XXXXX", "....X", "...X.", "..X..", ".X...", "X....", "XXXXX"],
	"!": ["..X..", "..X..", "..X..", "..X..", "..X..", ".....", "..X.."],
	"-": [".....", ".....", ".....", "XXXXX", ".....", ".....", "....."],
	"+": [".....", "..X..", "..X..", "XXXXX", "..X..", "..X..", "....."],
	":": [".....", "..X..", "..X..", ".....", "..X..", "..X..", "....."],
	"%": ["XX...", "XX..X", "...X.", "..X..", ".X...", "X..XX", "...XX"],
	".": [".....", ".....", ".....", ".....", ".....", ".....", "..X.."],
	",": [".....", ".....", ".....", ".....", "..X..", "..X..", ".X..."],
	"/": ["....X", "....X", "...X.", "..X..", ".X...", "X....", "X...."],
	"'": ["..X..", "..X..", ".....", ".....", ".....", ".....", "....."],
	"?": [".XXX.", "X...X", "....X", "...X.", "..X..", ".....", "..X.."],
	"(": ["...X.", "..X..", ".X...", ".X...", ".X...", "..X..", "...X."],
	")": [".X...", "..X..", "...X.", "...X.", "...X.", "..X..", ".X..."],
	"@": [".XXX.", "X...X", "X.XXX", "X.X.X", "X.XXX", "X....", ".XXXX"],
}

static func text_width(text: String, s: int) -> float:
	return float(text.length() * (W + 1) - 1) * float(s)

static func draw_text(ci: CanvasItem, text: String, pos: Vector2, s: int, color: Color) -> void:
	var cursor := pos
	for i in text.length():
		var ch := text[i].to_upper()
		if GLYPHS.has(ch):
			var rows: Array = GLYPHS[ch]
			for r in H:
				var line: String = rows[r]
				var run_start := -1
				for c in W + 1:
					var on := c < W and line[c] == "X"
					if on and run_start < 0:
						run_start = c
					elif not on and run_start >= 0:
						ci.draw_rect(Rect2(cursor + Vector2(run_start * s, r * s),
							Vector2((c - run_start) * s, s)), color)
						run_start = -1
		cursor.x += float(W + 1) * float(s)

static func draw_centered(ci: CanvasItem, text: String, center_x: float, y: float, s: int, color: Color) -> void:
	draw_text(ci, text, Vector2(center_x - text_width(text, s) * 0.5, y), s, color)
