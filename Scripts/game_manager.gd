extends Node

# Player Stats
var saved_health: int = -1
var saved_currency: int = 0

# Checkpoints
var current_checkpoint_pos: Vector2 = Vector2.ZERO
var current_checkpoint_level: String = ""
var has_checkpoint: bool = false

# Progression / Kills
var enemy_kill_counts: Dictionary = {}

func save_player_state(health: int, currency: int) -> void:
	saved_health = health
	saved_currency = currency

func save_checkpoint(pos: Vector2, level_tag: String) -> void:
	current_checkpoint_pos = pos
	current_checkpoint_level = level_tag
	has_checkpoint = true

func get_enemy_kills(enemy_id: String) -> int:
	return enemy_kill_counts.get(enemy_id, 0)

func register_enemy_kill(enemy_id: String) -> void:
	if enemy_id == "":
		return
	enemy_kill_counts[enemy_id] = get_enemy_kills(enemy_id) + 1

func get_total_kills() -> int:
	var total := 0
	for kills in enemy_kill_counts.values():
		total += kills
	return total
