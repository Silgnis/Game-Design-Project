extends Node2D

@export var target: CharacterBody2D             
@export var follow_offset := Vector2(-14, -12)  # behind and on top of player
@export var follow_speed := 4.0                 # higher = closer to the player
@export var bob_amplitude := 2.0				# how much the wobbling is afected in pixels
@export var bob_speed := 3.0					# controls the speed of the ghost going up and down

@onready var sprite: Sprite2D = $Sprite2D

var _time := 0.0

func _ready() -> void:
	modulate.a = 0.7   # Unnecessary, but it looks nice to be a bit faded

func _physics_process(delta: float) -> void:
	if target == null:
		return

	_time += delta

	var offset := follow_offset
	if target.velocity.x < 0:
		offset.x = -follow_offset.x

	var goal := target.global_position + offset
	goal.y += sin(_time * bob_speed) * bob_amplitude	# Weird formula to make it float

	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))			# lerp makes the ghost advance t (between 100% and 0%) of the way to the goal position

	if absf(goal.x - global_position.x) > 1.0:				# to change the sprite to follow along
		sprite.flip_h = goal.x < global_position.x
