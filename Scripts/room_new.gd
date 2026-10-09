extends Node2D
class_name Room

# The area this room owns, in the room's local coordinates. The World camera centres on it
# when the player is inside, so it should match one screen (zoom 2.1 shows about 549x309).
@export var bounds := Rect2(-280, -160, 560, 320)
# Optional icon the map draws on this room, e.g. a campfire for a rest room.
@export var map_icon: Texture2D

func _ready() -> void:
	add_to_group("rooms")

func get_global_bounds() -> Rect2:
	return Rect2(global_position + bounds.position, bounds.size)

func has_point(point: Vector2) -> bool:
	return get_global_bounds().has_point(point)

# An exit is open when nothing solid (any enabled TileMapLayer whose TileSet has physics)
# sits in its gap. Exits are at the centre of each edge: E/W across rows -1..1, N/S across
# columns -2..1, so this works for rooms with ExitNorth/... layers and for hand-made ones.
func is_exit_open(dir: Vector2i) -> bool:
	var layers := find_children("*", "TileMapLayer", true, false)
	for point in _exit_points(dir):
		for layer: TileMapLayer in layers:
			if not layer.enabled or layer.tile_set == null or layer.tile_set.get_physics_layers_count() == 0:
				continue
			var cell := layer.local_to_map(layer.to_local(to_global(point)))
			if layer.get_cell_source_id(cell) != -1:
				return false
	return true

# Sample points in the outer two tile rows/columns of the given edge, across the exit gap.
func _exit_points(dir: Vector2i) -> Array[Vector2]:
	var c := bounds.get_center()
	var points: Array[Vector2] = []
	match dir:
		Vector2i.UP, Vector2i.DOWN:
			var edge := bounds.position.y if dir == Vector2i.UP else bounds.end.y
			var inward := 1.0 if dir == Vector2i.UP else -1.0
			for depth in [8.0, 24.0]:
				for x in [-24.0, -8.0, 8.0, 24.0]:
					points.append(Vector2(c.x + x, edge + inward * depth))
		Vector2i.LEFT, Vector2i.RIGHT:
			var edge := bounds.position.x if dir == Vector2i.LEFT else bounds.end.x
			var inward := 1.0 if dir == Vector2i.LEFT else -1.0
			for depth in [-4.0, 8.0, 20.0]:
				for y in [-8.0, 8.0, 24.0]:
					points.append(Vector2(edge + inward * depth, c.y + y))
	return points
