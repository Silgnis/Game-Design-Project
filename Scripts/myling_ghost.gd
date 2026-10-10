extends Node2D

@export var target: CharacterBody2D             
@export var follow_offset := Vector2(-14, -12)  # Base offset behind and above player
@export var follow_speed := 4.0                 # Higher = closer to player
@export var bob_amplitude := 2.0                # Wobble height in pixels
@export var bob_speed := 3.0                    # Speed of floating motion

@export var attack_anim_time := 0.3

const ATTACK_TEXTURE = preload("res://Resources/Custom Assets/Player/Myling Attack.png") # 4 frames
const RECHARGE_TEXTURE = preload("res://Resources/Custom Assets/Player/Myling Recharge.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var idle_texture: Texture2D = sprite.texture

var _time := 0.0
var _facing_right := true  # Tracks player's horizontal facing direction

func _ready() -> void:
	modulate.a = 0.7
	# Force initial flipped state to match starting orientation
	update_sprite_flip()
	NavigationManager.on_trigger_player_spawn.connect(_on_player_spawn)
	if target and target.has_signal("myling_used"):
		target.myling_used.connect(_on_myling_used)
		target.myling_ready.connect(_on_myling_ready)

func _physics_process(delta: float) -> void:
	if target == null:
		return

	_time += delta

	# Update horizontal direction whenever the player moves left or right
	if target.velocity.x < 0 and _facing_right:
		_facing_right = false
		update_sprite_flip()
	elif target.velocity.x > 0 and not _facing_right:
		_facing_right = true
		update_sprite_flip()

	# Dynamic offset based on facing direction
	var current_offset := get_calculated_offset()
	var goal := target.global_position + current_offset
	goal.y += sin(_time * bob_speed) * bob_amplitude

	# Smooth movement toward target destination
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))

func update_sprite_flip() -> void:
	sprite.flip_h = _facing_right

func get_calculated_offset() -> Vector2:
	var offset := follow_offset
	# Mirror horizontal offset if facing left so follower stays behind player
	if not _facing_right:
		offset.x = -follow_offset.x
	return offset

func _on_player_spawn(spawn_position: Vector2) -> void:
	# Teleport instantly using the current directional offset
	global_position = spawn_position + get_calculated_offset()
	update_sprite_flip()

# Attack animation, then the dim recharge sprite until the ability is ready again
func _on_myling_used() -> void:
	_set_sprite(ATTACK_TEXTURE, 4)
	var anim = create_tween()
	anim.tween_property(sprite, "frame", 3, attack_anim_time)
	anim.tween_callback(_set_sprite.bind(RECHARGE_TEXTURE, 1))

func _on_myling_ready() -> void:
	_set_sprite(idle_texture, 1)
	sprite.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.2)

func _set_sprite(texture: Texture2D, frames: int) -> void:
	sprite.texture = texture
	sprite.hframes = frames
	sprite.frame = 0
