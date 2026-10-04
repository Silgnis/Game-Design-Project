extends Node

const scene_level_1 = preload("res://Scenes/Level1.tscn")
const scene_level_2 = preload("res://Scenes/Level2.tscn")

signal on_trigger_player_spawn

var spawn_door_tag

# Checkpoint tracking variables
var current_checkpoint_pos: Vector2 = Vector2.ZERO
var current_checkpoint_level: String = ""
var has_checkpoint: bool = false

func go_to_level(level_tag: String, destination_tag: String) -> void:
	var scene_to_load: PackedScene
	
	match level_tag:
		"level_1":
			scene_to_load = scene_level_1
		"level_2":
			scene_to_load = scene_level_2
		
	if scene_to_load != null:
		spawn_door_tag = destination_tag
		get_tree().change_scene_to_packed(scene_to_load)

func trigger_player_spawn(position: Vector2) -> void:
	on_trigger_player_spawn.emit(position)

func save_checkpoint(pos: Vector2, level_tag: String) -> void:
	current_checkpoint_pos = pos
	current_checkpoint_level = level_tag
	has_checkpoint = true

func respawn_player() -> void:
	if has_checkpoint:
		# Reload the saved level and skip door spawning
		spawn_door_tag = null
		go_to_level(current_checkpoint_level, "")
	else:
		# Fallback: if no checkpoint saved yet, just reload current active scene
		get_tree().reload_current_scene()
