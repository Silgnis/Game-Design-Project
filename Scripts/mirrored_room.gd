extends Room
class_name MirroredRoom

@export var layout_extents := Vector2(256, 128)

var _base_positions := {}

func _ready() -> void:
	super._ready()
	for node in get_children():
		if node is EnemySpawner:
			_base_positions[node] = node.position

func on_player_entered() -> void:
	var side := _entry_side()
	for spawner in _base_positions:
		spawner.position = _arrange(_base_positions[spawner], side)
	super.on_player_entered()

func _entry_side() -> Vector2i:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2i.LEFT
	var offset := (to_local(player.global_position) - bounds.get_center()) / (bounds.size / 2.0)
	if absf(offset.x) >= absf(offset.y):
		return Vector2i.LEFT if offset.x < 0 else Vector2i.RIGHT
	return Vector2i.UP if offset.y < 0 else Vector2i.DOWN

func _arrange(base: Vector2, side: Vector2i) -> Vector2:
	var n := base / layout_extents
	match side:
		Vector2i.RIGHT:
			n = Vector2(-n.x, n.y)
		Vector2i.UP:
			n = Vector2(n.y, n.x)
		Vector2i.DOWN:
			n = Vector2(n.y, -n.x)
	return n * layout_extents
