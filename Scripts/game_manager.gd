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

var owned_items: Array[String] = []

# Souls the player destroyed for good (killed every form of that enemy), as
# enemy_id -> enemy scene path. The boss reacts to the count and summons from these scenes.
var destroyed_souls: Dictionary = {}

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

func register_soul_destroyed(enemy_id: String, scene_path: String) -> void:
	destroyed_souls[enemy_id] = scene_path

func get_destroyed_soul_count() -> int:
	return destroyed_souls.size()

# One scene path per destroyed soul (duplicates when several souls were the same enemy type)
func get_destroyed_soul_scenes() -> Array:
	return destroyed_souls.values()

func has_item(item_id: String) -> bool:
	return item_id in owned_items

func add_item(item_id: String) -> void:
	if not has_item(item_id):
		owned_items.append(item_id)
