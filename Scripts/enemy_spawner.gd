extends Marker2D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var enemy_id: String = ""

var spawned_enemy: EnemyBase = null

func spawn_enemy() -> void:
	if spawned_enemy != null or enemy_scene == null or enemy_id.is_empty():
		return
	
	# Instantiate and place at this marker's position
	var instance := enemy_scene.instantiate() as EnemyBase
	instance.enemy_id = enemy_id
	get_parent().add_child(instance)
	instance.global_position = global_position
	spawned_enemy = instance

func despawn_enemy() -> void:
	if is_instance_valid(spawned_enemy):
		spawned_enemy.queue_free()
		spawned_enemy = null
