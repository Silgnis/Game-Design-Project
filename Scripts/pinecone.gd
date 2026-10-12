extends Area2D

# 1. Scatter: flies straight out along its fan direction, slowly
# 2. Home: accelerates and gently steers toward the player
# 3. Lock: once close, stops steering and only keeps speeding up, so it can be sidestepped
@export var start_speed: float = 50.0
@export var max_speed: float = 260.0
@export var acceleration: float = 140.0
@export var scatter_time: float = 0.45
@export var turn_speed: float = 1.8 # Max radians per second it can steer toward the player
@export var lock_distance: float = 60.0
@export var lifetime: float = 5.0
# Buffed pinecones are faster, steer harder and fly over trees (only the player stops them)
@export var buffed_speed_mult: float = 1.4
@export var buffed_turn_mult: float = 1.3
@export var damage: int = 1
@export var face_turn_speed: float = 12.0 # How quickly the tip swings to its new facing

const BUFFED_TINT = Color(1.6, 0.6, 0.5) # Buffed pinecones are the same sprite, tinted red

@onready var sprite: Sprite2D = $Sprite2D

var direction = Vector2.RIGHT
var target: Node2D
var buffed := false
var speed := 0.0
var time_scale := 1.0 # Lowered while the boss is slowed by the myling
var _age := 0.0
var _locked := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if buffed:
		max_speed *= buffed_speed_mult
		acceleration *= buffed_speed_mult
		turn_speed *= buffed_turn_mult
		collision_mask = 2 # Player only
		sprite.modulate = BUFFED_TINT
	speed = start_speed
	rotation = _facing_angle()

func set_time_scale(value: float) -> void:
	time_scale = value

func _physics_process(delta: float) -> void:
	delta *= time_scale
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	if _age >= scatter_time:
		speed = move_toward(speed, max_speed, acceleration * delta)
		if not _locked and is_instance_valid(target):
			var to_target = target.global_position - global_position
			if to_target.length() <= lock_distance:
				_locked = true
			else:
				var max_turn = turn_speed * delta
				direction = direction.rotated(clampf(direction.angle_to(to_target), -max_turn, max_turn))

	position += direction * speed * delta
	rotation = lerp_angle(rotation, _facing_angle(), 1.0 - exp(-face_turn_speed * delta))

# The sprite's tip points down. While scattering near the boss the tip aims at the player;
# once it speeds off, it points where it's flying.
func _facing_angle() -> float:
	var facing: Vector2 = direction
	if _age < scatter_time and is_instance_valid(target):
		facing = target.global_position - global_position
	return facing.angle() - PI / 2

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
