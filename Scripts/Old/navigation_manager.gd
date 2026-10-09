extends Node

const scene_level_1 = preload("res://Scenes/Old/Level1.tscn")
const scene_level_2 = preload("res://Scenes/Old/Level2.tscn")

signal on_trigger_player_spawn

var spawn_door_tag

func go_to_level(level_tag: String, destination_tag: String) -> void:
	var scene_to_load: PackedScene
	
	match level_tag:
		"level_1":
			scene_to_load = scene_level_1
		"level_2":
			scene_to_load = scene_level_2
		
	if scene_to_load != null:
		spawn_door_tag = destination_tag
		get_tree().call_deferred("change_scene_to_packed", scene_to_load)

func trigger_player_spawn(position: Vector2) -> void:
	on_trigger_player_spawn.emit(position)

func respawn_player() -> void:
	if GameManager.has_checkpoint:
		spawn_door_tag = ""
		go_to_level(GameManager.current_checkpoint_level, "")
	else:
		get_tree().call_deferred("reload_current_scene")
