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
@export var spin_speed: float = 8.0

const BODY_COLOR = Color(0.45, 0.28, 0.14)
const SCALE_COLOR = Color(0.28, 0.16, 0.07)
const BUFFED_BODY_COLOR = Color(0.65, 0.18, 0.1)

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
	speed = start_speed

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
	rotation += spin_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

# Placeholder art until there's a pinecone sprite
func _draw() -> void:
	var points = PackedVector2Array()
	for i in 12:
		var a = TAU * i / 12
		points.append(Vector2(cos(a) * 4.0, sin(a) * 5.5))
	draw_colored_polygon(points, BUFFED_BODY_COLOR if buffed else BODY_COLOR)
	for y in [-2.5, 0.0, 2.5]:
		draw_line(Vector2(-3, y), Vector2(3, y), SCALE_COLOR, 1.0)
