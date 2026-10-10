extends Node2D

# Normal: trees sprout one by one around a circle, closing in from one side so the last gap
# is on the opposite side. Once closed they turn into thorny bushes that hurt anyone inside.
# Trap (instant + breakable): the whole ring appears at once with no gap, and the player
# has to shoot a tree down to get out before the bushes take over.

@export var radius: float = 60.0
@export var tree_count: int = 14
@export var close_time: float = 1.4 # Time from the first tree to the ring being fully closed
@export var closed_hold: float = 0.4 # Pause with the ring closed before the bushes take over
@export var bush_duration: float = 6.0
@export var damage: int = 1
@export var damage_interval: float = 0.8

@export_group("Trap")
@export var instant: bool = false # Whole ring at once instead of closing gradually
@export var breakable: bool = false # Player bullets can chop the trees down
@export var trap_time: float = 4.0 # With instant, how long until the bushes take over
@export var tree_health: int = 40

const BUSH_DARK = Color(0.12, 0.32, 0.12)
const BUSH_LIGHT = Color(0.25, 0.5, 0.2)
const THORN_COLOR = Color(0.55, 0.4, 0.2)

enum State { CLOSING, BUSHES }

@onready var timer: Timer = $Timer

var target: Node2D
var state := State.CLOSING
var trees: Array[BossTree] = []
var bushes: Array[Vector3] = [] # x, y = position, z = size
var damage_cooldown := 0.0
var time_scale := 1.0 # Lowered while the boss is slowed by the myling
var start_angle := NAN # Where the first tree grows (the gap closes opposite); random if not set

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	if instant:
		_run_trap()
	else:
		_run_closing()

func _physics_process(delta: float) -> void:
	if state != State.BUSHES or not is_instance_valid(target):
		return
	damage_cooldown -= delta
	if damage_cooldown <= 0.0 and global_position.distance_to(target.global_position) <= radius:
		target.take_damage(damage)
		damage_cooldown = damage_interval

func _run_closing() -> void:
	if is_nan(start_angle):
		start_angle = randf() * TAU
	var step_angle = TAU / tree_count
	var steps = floori(tree_count / 2.0)
	var delay = close_time / steps

	# Grow out from the start angle in both directions; the gap closes on the far side
	_spawn_tree(start_angle)
	for i in range(1, steps + 1):
		await wait(delay)
		_spawn_tree(start_angle + i * step_angle)
		if i * 2 != tree_count:
			_spawn_tree(start_angle - i * step_angle)

	await wait(closed_hold)
	await _bushes_then_fade()

func _run_trap() -> void:
	for i in tree_count:
		_spawn_tree(TAU * i / tree_count)
	await wait(trap_time)
	await _bushes_then_fade()

func _bushes_then_fade() -> void:
	_fill_with_bushes()
	await wait(bush_duration)
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.5)
	fade.finished.connect(queue_free)

# Child Timer, so the sequence just stops if the circle is freed (e.g. the boss dies)
func wait(seconds: float) -> void:
	timer.start(seconds / time_scale)
	await timer.timeout

func set_time_scale(value: float) -> void:
	# Stretch whatever is left of the current wait
	if timer and timer.time_left > 0.0:
		timer.start(timer.time_left * time_scale / value)
	time_scale = value

func _spawn_tree(angle: float) -> void:
	var tree = BossTree.new()
	tree.position = Vector2.RIGHT.rotated(angle) * radius
	tree.breakable = breakable
	tree.health = tree_health
	# Neighbouring trunks must touch, otherwise the player slips between them
	tree.collision_radius = maxf(7.0, radius * sin(PI / tree_count) + 1.5)
	add_child(tree)
	trees.append(tree)

func _fill_with_bushes() -> void:
	state = State.BUSHES
	for tree in trees:
		if is_instance_valid(tree):
			tree.queue_free()
	trees.clear()

	# Scatter bush clumps over the whole circle, roughly evenly
	var count = int(radius * radius / 60.0)
	for i in count:
		var p = Vector2.RIGHT.rotated(randf() * TAU) * sqrt(randf()) * radius
		bushes.append(Vector3(p.x, p.y, randf_range(5.0, 8.0)))

	scale = Vector2(0.6, 0.6)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

# Placeholder art until there are proper bush sprites
func _draw() -> void:
	if state != State.BUSHES:
		return
	for b in bushes:
		var p = Vector2(b.x, b.y)
		draw_circle(p, b.z, BUSH_DARK)
		draw_circle(p + Vector2(-b.z * 0.3, -b.z * 0.3), b.z * 0.55, BUSH_LIGHT)
		draw_line(p + Vector2(b.z * 0.4, 0), p + Vector2(b.z * 0.9, -b.z * 0.4), THORN_COLOR, 1.0)
