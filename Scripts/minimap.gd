extends Control
class_name Minimap

# Isaac-style map. A small panel in the top-right shows the rooms around the current one;
# holding Tab shows everything explored so far. A room appears (dim) once you've been in a
# room connected to it, fills in when visited, and the current room is highlighted.
# Room positions come from the World grid: each room sits at a multiple of its bounds size.

@export var cell_size := Vector2(26, 15)
@export var gap := 4.0
@export var radius := 2            # rooms shown on each side of the current one in the corner panel
@export var expanded_scale := 2.0  # size of the Tab map relative to the corner panel
@export var margin := 16.0

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const COLOR_PANEL := Color(0, 0, 0, 0.45)
const COLOR_OVERLAY := Color(0, 0, 0, 0.6)
const COLOR_EDGE := Color(0.05, 0.06, 0.05)
const COLOR_SEEN := Color(0.24, 0.27, 0.24)
const COLOR_VISITED := Color(0.56, 0.62, 0.55)
const COLOR_CURRENT := Color(0.96, 0.97, 0.9)

var _rooms := {}     # Vector2i -> Room
var _cells := {}     # Room -> Vector2i
var _visited := {}   # Vector2i -> true
var _current := Vector2i.ZERO
var _expanded := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func setup(rooms: Array) -> void:
	_rooms.clear()
	_cells.clear()
	_visited.clear()
	for room: Room in rooms:
		var cell := Vector2i((room.get_global_bounds().get_center() / room.bounds.size).round())
		_rooms[cell] = room
		_cells[room] = cell
	queue_redraw()

func set_current(room: Room) -> void:
	if not _cells.has(room):
		return
	_current = _cells[room]
	_visited[_current] = true
	queue_redraw()

func _process(_delta: float) -> void:
	var held := Input.is_physical_key_pressed(KEY_TAB)
	if held != _expanded:
		_expanded = held
		queue_redraw()

func _draw() -> void:
	if _visited.is_empty():
		return
	if _expanded:
		draw_rect(Rect2(Vector2.ZERO, size), COLOR_OVERLAY)
		_draw_rooms(size / 2, _explored_center(), cell_size * expanded_scale, gap * expanded_scale, -1)
	else:
		var step := cell_size + Vector2(gap, gap)
		var panel := step * (radius * 2 + 1) + Vector2(gap, gap)
		var top_left := Vector2(size.x - margin - panel.x, margin)
		draw_rect(Rect2(top_left, panel), COLOR_PANEL)
		_draw_rooms(top_left + panel / 2, Vector2(_current), cell_size, gap, radius)

# Draws known rooms around `focus` (a grid position) with `focus` at `center` on screen.
# limit < 0 draws every known room, otherwise only those within `limit` cells of the current one.
func _draw_rooms(center: Vector2, focus: Vector2, cell: Vector2, spacing: float, limit: int) -> void:
	var step := cell + Vector2(spacing, spacing)
	var shown: Array[Vector2i] = []
	for pos: Vector2i in _rooms:
		var d := pos - _current
		if limit >= 0 and (absi(d.x) > limit or absi(d.y) > limit):
			continue
		if _is_known(pos):
			shown.append(pos)

	# Doorways first, so the rooms are drawn over the ends of each connector.
	for pos in shown:
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var other := pos + dir
			if other in shown and _linked(pos, dir) and (_visited.has(pos) or _visited.has(other)):
				var a := center + (Vector2(pos) - focus) * step
				var b := center + (Vector2(other) - focus) * step
				draw_line(a, b, COLOR_EDGE, spacing + 2)
				draw_line(a, b, COLOR_VISITED, spacing)

	for pos in shown:
		var rect := Rect2(center + (Vector2(pos) - focus) * step - cell / 2, cell)
		var fill := COLOR_SEEN
		if pos == _current:
			fill = COLOR_CURRENT
		elif _visited.has(pos):
			fill = COLOR_VISITED
		draw_rect(rect.grow(1), COLOR_EDGE)
		draw_rect(rect, fill)
		var icon: Texture2D = _rooms[pos].map_icon
		if icon:
			var h := rect.size.y - 2
			var icon_size := Vector2(icon.get_width() * h / icon.get_height(), h)
			draw_texture_rect(icon, Rect2(rect.get_center() - icon_size / 2, icon_size), false)

# Rooms are revealed once visited or once a visited room has a doorway into them.
func _is_known(pos: Vector2i) -> bool:
	if _visited.has(pos):
		return true
	for dir in DIRS:
		if _visited.has(pos + dir) and _linked(pos, dir):
			return true
	return false

# True when both rooms exist and both sides of the shared edge have their exit open.
func _linked(pos: Vector2i, dir: Vector2i) -> bool:
	var other := pos + dir
	if not _rooms.has(pos) or not _rooms.has(other):
		return false
	return _rooms[pos].is_exit_open(dir) and _rooms[other].is_exit_open(-dir)

func _explored_center() -> Vector2:
	var known: Array[Vector2i] = []
	for pos: Vector2i in _rooms:
		if _is_known(pos):
			known.append(pos)
	var lo := Vector2(known[0])
	var hi := lo
	for pos in known:
		lo = lo.min(Vector2(pos))
		hi = hi.max(Vector2(pos))
	return (lo + hi) / 2
