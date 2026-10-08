extends Node

# Player Stats
var saved_health: int = -1
var saved_currency: int = 0

# Checkpoints
var current_checkpoint_pos: Vector2 = Vector2.ZERO
var current_checkpoint_level: String = ""
var has_checkpoint: bool = false

func save_player_state(health: int, currency: int) -> void:
	saved_health = health
	saved_currency = currency

func save_checkpoint(pos: Vector2, level_tag: String) -> void:
	current_checkpoint_pos = pos
	current_checkpoint_level = level_tag
	has_checkpoint = true
