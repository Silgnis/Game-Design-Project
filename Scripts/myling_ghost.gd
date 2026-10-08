extends Node2D

@export var target: CharacterBody2D             
@export var follow_offset := Vector2(-14, -12)  # Base offset behind and above player
@export var follow_speed := 4.0                 # Higher = closer to player
@export var bob_amplitude := 2.0				# Wobble height in pixels
@export var bob_speed := 3.0					# Speed of floating motion

@onready var sprite: Sprite2D = $Sprite2D

var _time := 0.0
var _facing_right := true  # Tracks player's horizontal facing direction

func _ready() -> void:
	modulate.a = 0.7
	NavigationManager.on_trigger_player_spawn.connect(_on_player_spawn)

func _physics_process(delta: float) -> void:
	if target == null:
		return

	_time += delta

	# Update horizontal direction whenever the player moves left or right
	if target.velocity.x < 0:
		_facing_right = false
	elif target.velocity.x > 0:
		_facing_right = true

	# Dynamic offset based on facing direction
	var current_offset := get_calculated_offset()
	var goal := target.global_position + current_offset
	goal.y += sin(_time * bob_speed) * bob_amplitude

	# Smooth movement toward target destination
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))

	# Flip sprite based on movement goal
	if absf(goal.x - global_position.x) > 1.0:
		sprite.flip_h = goal.x < global_position.x

func get_calculated_offset() -> Vector2:
	var offset := follow_offset
	# Mirror horizontal offset if facing left so follower stays behind player
	if not _facing_right:
		offset.x = -follow_offset.x
	return offset

func _on_player_spawn(spawn_position: Vector2) -> void:
	# Teleport instantly using the current directional offset
	global_position = spawn_position + get_calculated_offset()
