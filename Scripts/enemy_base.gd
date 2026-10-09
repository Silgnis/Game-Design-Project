extends Node2D
class_name EnemyBase

@export_group("Enemy Identity")
@export var enemy_id: String = "generic_enemy"

@export_group("Stats")
@export var max_health: int = 100
@export var coin_scene: PackedScene = preload("res://Scenes/Coin.tscn")
@export var coin_drop_radius: float = 12.0

@export_group("Progression Stages")
# Index 0 = 0 kills, 1 = 1 kill, 2 = 2 kills, ...
@export var stage_sprites: Array[Texture2D] = []
@export var stage_coin_drops: Array[int] = [0, 3, 5]

@onready var hurt_sfx: AudioStreamPlayer2D = get_node_or_null("HurtSFX")

var current_health: int
var is_dead: bool = false
var stage_index: int = 0

func _ready() -> void:
	var kills = GameManager.get_enemy_kills(enemy_id)

	# Past the final stage: don't spawn at all
	if stage_sprites.size() > 0 and kills >= stage_sprites.size():
		queue_free()
		return

	stage_index = clampi(kills, 0, max(stage_sprites.size() - 1, 0))
	current_health = max_health
	update_appearance()

func update_appearance() -> void:
	if stage_sprites.size() == 0:
		return
	var sprite_node = get_node_or_null("Sprite2D")
	if sprite_node is Sprite2D and stage_sprites[stage_index] != null:
		sprite_node.texture = stage_sprites[stage_index]

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	flash_red()
	if hurt_sfx:
		hurt_sfx.pitch_scale = randf_range(0.9, 1.1)
		hurt_sfx.play()
	if current_health <= 0:
		die()

func flash_red() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	drop_coins()
	GameManager.register_enemy_kill(enemy_id)
	queue_free()

func drop_coins() -> void:
	if coin_scene == null or stage_coin_drops.size() == 0:
		return
	var coins_to_drop = stage_coin_drops[clampi(stage_index, 0, stage_coin_drops.size() - 1)]
	for i in coins_to_drop:
		var coin = coin_scene.instantiate()
		var offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(4.0, coin_drop_radius)
		coin.global_position = global_position + offset
		# Deferred because die() usually runs inside a physics callback
		get_tree().current_scene.add_child.call_deferred(coin)
