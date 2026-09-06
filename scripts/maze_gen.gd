class_name MazeGen
extends RefCounted

const OPEN := 0
const WALL := 1
const DOOR := 2

const ROW_SKELS_TOP := [[1, 4, 8], [1, 5, 8], [2, 5, 8]]
const ROW_SKELS_BOTTOM := [[20, 23, 26, 29], [20, 24, 28], [20, 23, 27], [20, 24, 27]]
const BAND_ROWS := [1, 2, 3, 4, 5, 6, 7, 8, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
const REQUIRED := [
	Vector2i(6, 8), Vector2i(12, 8), Vector2i(15, 8), Vector2i(21, 8),
	Vector2i(6, 20), Vector2i(9, 20), Vector2i(18, 20), Vector2i(21, 20),
]
const START_TILES := [Vector2i(13, 23), Vector2i(14, 23)]
const COL_STARTS := [1, 1, 1, 2]
const COL_GAPS := [3, 3, 4, 4, 5]
const LAST_COL := 12
const MAX_ATTEMPTS := 80
const MIN_DOTS := 185
const MAX_WALL_BLOB := 58
const MIN_OPEN_FRACTION := 0.36
const MAX_OPEN_FRACTION := 0.64
const CARVE_MIN := 0.22
const CARVE_MAX := 0.48

static func generate(maze_seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = maze_seed
	for attempt in MAX_ATTEMPTS:
		var rows := _attempt(rng)
		if not rows.is_empty():
			return rows
	return PM.MAZE_CLASSIC.duplicate()

static func _attempt(rng: RandomNumberGenerator) -> Array:
	var cols_top := _pick_cols(rng)
	var cols_bottom := _pick_cols(rng)
	if cols_top.is_empty() or cols_bottom.is_empty():
		return []
	var grid := _blank()
	var segments := _open_band(grid, _pick(ROW_SKELS_TOP, rng), cols_top)
	segments.append_array(_open_band(grid, _pick(ROW_SKELS_BOTTOM, rng), cols_bottom))
	if not _valid(grid):
		return []
	_carve(grid, segments, rng, rng.randf_range(CARVE_MIN, CARVE_MAX))
	if not _valid(grid) or not _good_looking(grid):
		return []
	return _with_pellets(grid, rng)

static func _pick(options: Array, rng: RandomNumberGenerator) -> Array:
	return options[rng.randi_range(0, options.size() - 1)]

static func _pick_cols(rng: RandomNumberGenerator) -> Array:
	var cols: Array[int] = [COL_STARTS[rng.randi_range(0, COL_STARTS.size() - 1)]]
	while true:
		var next_col: int = cols[cols.size() - 1] + COL_GAPS[rng.randi_range(0, COL_GAPS.size() - 1)]
		if next_col > LAST_COL:
			break
		cols.append(next_col)
	return cols if cols.size() >= 3 else []

static func _blank() -> Array:
	var grid: Array = []
	grid.resize(PM.ROWS * PM.COLS)
	grid.fill(WALL)
	for y in range(9, 20):
		var line: String = PM.MAZE_CLASSIC[y]
		for x in PM.COLS:
			var ch := line[x]
			if ch == "#":
				continue
			grid[y * PM.COLS + x] = DOOR if ch == "-" else OPEN
	return grid

static func _open_band(grid: Array, rows: Array, cols: Array) -> Array:
	var lanes: Array[int] = []
	for c: int in cols:
		lanes.append(c)
		lanes.append(PM.COLS - 1 - c)
	lanes.sort()
	var first_col: int = lanes[0]
	var last_col: int = lanes[lanes.size() - 1]
	var first_row: int = rows[0]
	var last_row: int = rows[rows.size() - 1]
	for r: int in rows:
		for x in range(first_col, last_col + 1):
			grid[r * PM.COLS + x] = OPEN
	for c: int in lanes:
		for y in range(first_row, last_row + 1):
			grid[y * PM.COLS + c] = OPEN
	var segments: Array = []
	for r: int in rows:
		for i in lanes.size() - 1:
			var cells: Array[Vector2i] = []
			for x in range(lanes[i] + 1, lanes[i + 1]):
				cells.append(Vector2i(x, r))
			if not cells.is_empty():
				segments.append(cells)
	for c: int in lanes:
		for i in rows.size() - 1:
			var cells: Array[Vector2i] = []
			for y in range(rows[i] + 1, rows[i + 1]):
				cells.append(Vector2i(c, y))
			if not cells.is_empty():
				segments.append(cells)
	return segments

static func _carve(grid: Array, segments: Array, rng: RandomNumberGenerator, fraction: float) -> void:
	var pairs: Array = []
	var seen := {}
	for cells: Array in segments:
		var key := _segment_key(cells)
		if seen.has(key):
			continue
		var mirrored := _mirror(cells)
		var mirror_key := _segment_key(mirrored)
		seen[key] = true
		seen[mirror_key] = true
		pairs.append(cells if mirror_key == key else cells + mirrored)
	_shuffle(pairs, rng)
	var limit := mini(int(float(pairs.size()) * fraction), pairs.size())
	for i in limit:
		var cells: Array = pairs[i]
		if _touches_required(cells):
			continue
		for c: Vector2i in cells:
			grid[c.y * PM.COLS + c.x] = WALL
		if not _valid(grid):
			for c: Vector2i in cells:
				grid[c.y * PM.COLS + c.x] = OPEN

static func _touches_required(cells: Array) -> bool:
	for c: Vector2i in cells:
		if REQUIRED.has(c) or START_TILES.has(c):
			return true
	return false

static func _segment_key(cells: Array) -> String:
	var first: Vector2i = cells[0]
	var last: Vector2i = cells[cells.size() - 1]
	var lo := Vector2i(mini(first.x, last.x), mini(first.y, last.y))
	var hi := Vector2i(maxi(first.x, last.x), maxi(first.y, last.y))
	return "%d,%d,%d,%d" % [lo.x, lo.y, hi.x, hi.y]

static func _mirror(cells: Array) -> Array:
	var out: Array[Vector2i] = []
	for i in range(cells.size() - 1, -1, -1):
		var c: Vector2i = cells[i]
		out.append(Vector2i(PM.COLS - 1 - c.x, c.y))
	return out

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp

static func _is_open(grid: Array, x: int, y: int) -> bool:
	return grid[y * PM.COLS + x] == OPEN

static func _in_house(x: int, y: int) -> bool:
	return x >= 11 and x <= 16 and y >= 13 and y <= 15

static func _open_neighbours(grid: Array, x: int, y: int) -> int:
	var count := 0
	for d: Vector2i in PM.TURN_ORDER:
		var n := _wrap(Vector2i(x + d.x, y + d.y))
		if n.x < 0 or n.x >= PM.COLS or n.y < 0 or n.y >= PM.ROWS:
			continue
		if _is_open(grid, n.x, n.y):
			count += 1
	return count

static func _wrap(t: Vector2i) -> Vector2i:
	if t.y == PM.TUNNEL_ROW:
		if t.x < 0:
			return Vector2i(PM.COLS - 1, t.y)
		if t.x >= PM.COLS:
			return Vector2i(0, t.y)
	return t

static func _valid(grid: Array) -> bool:
	for p: Vector2i in REQUIRED:
		if not _is_open(grid, p.x, p.y):
			return false
	for y: int in BAND_ROWS:
		for x in range(1, PM.COLS - 1):
			if _is_open(grid, x, y) and _open_neighbours(grid, x, y) < 2:
				return false
	for y: int in BAND_ROWS:
		if y == 8 or y == 29:
			continue
		for x in range(1, PM.COLS - 2):
			if _is_open(grid, x, y) and _is_open(grid, x + 1, y) \
					and _is_open(grid, x, y + 1) and _is_open(grid, x + 1, y + 1):
				return false
	return _connected(grid)

static func _connected(grid: Array) -> bool:
	var seen: Array = []
	seen.resize(PM.ROWS * PM.COLS)
	seen.fill(false)
	var start := START_TILES[0] as Vector2i
	if not _is_open(grid, start.x, start.y):
		return false
	seen[start.y * PM.COLS + start.x] = true
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for d: Vector2i in PM.TURN_ORDER:
			var n := _wrap(cur + d)
			if n.x < 0 or n.x >= PM.COLS or n.y < 0 or n.y >= PM.ROWS:
				continue
			var i := n.y * PM.COLS + n.x
			if seen[i] or grid[i] != OPEN:
				continue
			seen[i] = true
			stack.append(n)
	for y in PM.ROWS:
		for x in PM.COLS:
			if _is_open(grid, x, y) and not _in_house(x, y) and not seen[y * PM.COLS + x]:
				return false
	return true

static func _good_looking(grid: Array) -> bool:
	for band in [range(1, 9), range(20, 30)]:
		var rows: Array = []
		for r in band:
			rows.append(r)
		var total := rows.size() * (PM.COLS - 2)
		var open_count := 0
		for y: int in rows:
			for x in range(1, PM.COLS - 1):
				if _is_open(grid, x, y):
					open_count += 1
		var fraction := float(open_count) / float(total)
		if fraction < MIN_OPEN_FRACTION or fraction > MAX_OPEN_FRACTION:
			return false
		if _largest_wall_blob(grid, rows) > MAX_WALL_BLOB:
			return false
	return true

static func _largest_wall_blob(grid: Array, rows: Array) -> int:
	var inside := {}
	for y: int in rows:
		for x in range(1, PM.COLS - 1):
			inside[Vector2i(x, y)] = true
	var seen := {}
	var biggest := 0
	for key: Vector2i in inside:
		if seen.has(key) or _is_open(grid, key.x, key.y):
			continue
		var stack: Array[Vector2i] = [key]
		seen[key] = true
		var size := 0
		while not stack.is_empty():
			var cur: Vector2i = stack.pop_back()
			size += 1
			for d: Vector2i in PM.TURN_ORDER:
				var n: Vector2i = cur + d
				if seen.has(n) or not inside.has(n) or _is_open(grid, n.x, n.y):
					continue
				seen[n] = true
				stack.append(n)
		biggest = maxi(biggest, size)
	return biggest

static func _with_pellets(grid: Array, rng: RandomNumberGenerator) -> Array:
	var chars: Array = []
	for y in PM.ROWS:
		var row: Array[String] = []
		for x in PM.COLS:
			var v: int = grid[y * PM.COLS + x]
			row.append("#" if v == WALL else ("-" if v == DOOR else " "))
		chars.append(row)
	var edge_top: Array[Vector2i] = []
	var edge_bottom: Array[Vector2i] = []
	for y: int in BAND_ROWS:
		for x in range(1, PM.COLS - 1):
			if not _is_open(grid, x, y) or START_TILES.has(Vector2i(x, y)):
				continue
			chars[y][x] = "."
			if x <= 3:
				if y < 9:
					edge_top.append(Vector2i(x, y))
				else:
					edge_bottom.append(Vector2i(x, y))
	for y in range(9, 20):
		for x in [6, 21]:
			if _is_open(grid, x, y):
				chars[y][x] = "."
	if edge_top.is_empty() or edge_bottom.is_empty():
		return []
	for group: Array in [edge_top, edge_bottom]:
		var p: Vector2i = group[rng.randi_range(0, group.size() - 1)]
		chars[p.y][p.x] = "o"
		chars[p.y][PM.COLS - 1 - p.x] = "o"
	var rows: Array = []
	var dots := 0
	for y in PM.ROWS:
		var line := ""
		for x in PM.COLS:
			line += chars[y][x]
		dots += line.count(".")
		rows.append(line)
	return rows if dots >= MIN_DOTS else []
