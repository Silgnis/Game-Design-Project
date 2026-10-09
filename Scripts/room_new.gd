extends Node2D
class_name Room

# The area this room owns, in the room's local coordinates. The World camera centres on it
# when the player is inside, so it should match one screen (zoom 2.1 shows about 549x309).
@export var bounds := Rect2(-280, -160, 560, 320)

func _ready() -> void:
	add_to_group("rooms")

func get_global_bounds() -> Rect2:
	return Rect2(global_position + bounds.position, bounds.size)

func has_point(point: Vector2) -> bool:
	return get_global_bounds().has_point(point)
	
func on_player_entered() -> void:
	for spawner in get_children():
		if spawner is EnemySpawner:
			spawner.spawn_enemy()

func on_player_exited() -> void:
	for spawner in get_children():
		if spawner is EnemySpawner:
			spawner.despawn_enemy()
