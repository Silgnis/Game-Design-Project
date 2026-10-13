extends EnemyBase
class_name Goblin

@export var coal_scene: PackedScene = preload("res://Scenes/coal_bullet.tscn")
@export var cycle_time: float = 1.0
@export var hop_time: float = 0.35
@export var hop_distance: float = 18.0
@export var keep_distance: float = 80.0
@export var direction_spread: float = 0.5
@export var side_shot_min_degrees: float = 30.0
@export var side_shot_max_degrees: float = 90.0
@export var stage_walk_textures: Array[Texture2D] = []
@export var walk_frames: int = 4
@export var walk_fps: float = 12.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hand: Marker2D = $Hand

var target: Node2D
var room: Room
var spawned_projectiles: Array[Node2D] = []
var _cycle := 0.0
var _hop_left := 0.0
var _hop_dir := Vector2.ZERO
var _walk_time := 0.0
var _detour_side := 0

func _init() -> void:
	enemy_id = "goblin"
	max_health = 40

func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return
	target = get_tree().get_first_node_in_group("player")
	room = _find_room()
	_cycle = randf_range(0.0, cycle_time * 0.5)

func _exit_tree() -> void:
	if not is_dead:
		despawn_all_projectiles()

func _physics_process(delta: float) -> void:
	if is_dead or not is_active or not is_instance_valid(target):
		return
	sprite.flip_h = target.global_position.x > global_position.x
	sprite.offset.x = absf(sprite.offset.x) * (1 if sprite.flip_h else -1)
	hand.position.x = absf(hand.position.x) * (1 if sprite.flip_h else -1)
	_cycle += delta
	if _hop_left > 0.0:
		_hop_left -= delta
		velocity = _hop_dir * hop_distance / hop_time
		move_and_slide()
		_animate_walk(delta)
		if _hop_left <= 0.0:
			velocity = Vector2.ZERO
			update_appearance()
			shoot()
		return
	if _cycle >= cycle_time:
		_cycle -= cycle_time
		start_hop()

func start_hop() -> void:
	var to_target := target.global_position - global_position
	var toward := to_target.normalized()
	if to_target.length() <= keep_distance:
		_detour_side = 0
		_hop_dir = _retreat_direction(toward)
	else:
		_hop_dir = _approach_direction(toward)
	_hop_left = hop_time
	_walk_time = 0.0

func _approach_direction(toward: Vector2) -> Vector2:
	var wanted := toward.rotated(randf_range(-direction_spread, direction_spread))
	if _is_clear(toward):
		_detour_side = 0
		return wanted if _is_clear(wanted) else toward
	if _detour_side == 0:
		_detour_side = 1 if randf() < 0.5 else -1
	for side in [_detour_side, -_detour_side]:
		for angle in [PI / 4, PI / 2, 3 * PI / 4]:
			var candidate := toward.rotated(angle * side)
			if _is_clear(candidate):
				_detour_side = side
				return candidate
	return -toward

func _retreat_direction(toward: Vector2) -> Vector2:
	var options: Array[Vector2] = [toward.orthogonal(), -toward.orthogonal(), -toward]
	options.shuffle()
	for option in options:
		var wanted := option.rotated(randf_range(-direction_spread, direction_spread))
		if _is_clear(wanted):
			return wanted
		if _is_clear(option):
			return option
	for i in 16:
		var candidate := Vector2.RIGHT.rotated(TAU * i / 16.0)
		if candidate.dot(toward) <= sin(direction_spread) and _is_clear(candidate):
			return candidate
	return Vector2.ZERO

func _is_clear(dir: Vector2) -> bool:
	return not test_move(global_transform, dir * hop_distance)

func shoot() -> void:
	if coal_scene == null or not is_instance_valid(target):
		return
	if room and not room.has_point(target.global_position):
		return
	var aim := (target.global_position - hand.global_position).normalized()
	_fire(aim)
	var side := 1.0 if randf() < 0.5 else -1.0
	_fire(aim.rotated(side * deg_to_rad(randf_range(side_shot_min_degrees, side_shot_max_degrees))))

func _fire(dir: Vector2) -> void:
	var coal = coal_scene.instantiate()
	coal.global_position = hand.global_position
	coal.direction = dir
	register_spawned_node(coal)
	get_tree().current_scene.add_child(coal)

func register_spawned_node(node: Node2D) -> void:
	spawned_projectiles.append(node)
	node.tree_exited.connect(func(): spawned_projectiles.erase(node))

func despawn_all_projectiles() -> void:
	for proj in spawned_projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	spawned_projectiles.clear()

func update_appearance() -> void:
	var sprite_node := get_node_or_null("Sprite2D") as Sprite2D
	if sprite_node:
		sprite_node.frame = 0
		sprite_node.hframes = 1
	super.update_appearance()

func _animate_walk(delta: float) -> void:
	if stage_index >= stage_walk_textures.size() or stage_walk_textures[stage_index] == null:
		return
	var walk := stage_walk_textures[stage_index]
	if sprite.texture != walk:
		sprite.texture = walk
		sprite.hframes = walk_frames
	_walk_time += delta
	sprite.frame = int(_walk_time * walk_fps) % walk_frames

func _find_room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node
