extends Node2D

# The boss's AOE field. A shadow grows out from the boss to the edge of the arena over
# shadow_time: that's the countdown to the blast. Meanwhile thorns creep in from the edges
# toward the boss until only a ring of safe_radius is left. Thorns have no collision, so
# bullets go straight through them, but standing in them hurts.

@export var safe_radius: float = 70.0
@export var outer_radius: float = 340.0 # Far enough to cover the whole arena from the boss
@export var close_time: float = 2.0 # Time for the thorns to creep from outer_radius to safe_radius
@export var shadow_time: float = 2.0 # Time for the shadow to grow from the boss to outer_radius
@export var damage: int = 1
@export var damage_interval: float = 0.8
@export var spacing: float = 13.0

const TEXTURE = preload("res://Resources/Custom Assets/obstacles.png")
const REGIONS = [Rect2(80, 48, 16, 11), Rect2(80, 69, 16, 10)]
const SHADOW_COLOR = Color(0.05, 0.0, 0.1, 0.35)
const SHADOW_EDGE_COLOR = Color(0.3, 0.05, 0.15, 0.7)

var target: Node2D
var time_scale := 1.0
var damage_cooldown := 0.0
var _inner: float
var _shadow := 0.0
var _thorns: Array[Vector3] = [] # x, y = position, z = which region; sorted far to near

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	_inner = outer_radius

	# Jittered grid over the ring between safe_radius and outer_radius
	var steps = ceili(outer_radius / spacing)
	for gx in range(-steps, steps + 1):
		for gy in range(-steps, steps + 1):
			var p = Vector2(gx, gy) * spacing + Vector2(randf_range(-4, 4), randf_range(-4, 4))
			var d = p.length()
			if d >= safe_radius and d <= outer_radius:
				_thorns.append(Vector3(p.x, p.y, randi() % REGIONS.size()))
	_thorns.sort_custom(func(a, b): return Vector2(a.x, a.y).length() > Vector2(b.x, b.y).length())

func set_time_scale(value: float) -> void:
	time_scale = value

func _process(delta: float) -> void:
	_inner = move_toward(_inner, safe_radius, (outer_radius - safe_radius) / close_time * delta * time_scale)
	_shadow = move_toward(_shadow, outer_radius, outer_radius / shadow_time * delta * time_scale)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	damage_cooldown -= delta
	var d = global_position.distance_to(target.global_position)
	if damage_cooldown <= 0.0 and d >= _inner and d <= outer_radius:
		target.take_damage(damage)
		damage_cooldown = damage_interval

func retract() -> void:
	set_process(false)
	set_physics_process(false)
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.3)
	fade.finished.connect(queue_free)

func _draw() -> void:
	if _shadow > 0.0:
		draw_circle(Vector2.ZERO, _shadow, SHADOW_COLOR)
		draw_arc(Vector2.ZERO, _shadow, 0, TAU, 64, SHADOW_EDGE_COLOR, 2.0)
	for t in _thorns:
		var p = Vector2(t.x, t.y)
		if p.length() < _inner:
			break
		var region: Rect2 = REGIONS[int(t.z)]
		draw_texture_rect_region(TEXTURE, Rect2(p - region.size / 2, region.size), region)
