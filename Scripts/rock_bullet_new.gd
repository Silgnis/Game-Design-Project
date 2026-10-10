extends Area2D

# A thrown rock: flies for split_time seconds, then bursts into a star of pebbles.
# Hitting the player or a wall before that stops it without splitting.
@export var SPEED = 55.0
@export var damage: int = 10
@export var split_time: float = 1.2
@export var pebble_scene: PackedScene = preload("res://Scenes/pebble_bullet_new.tscn")
@export var pebble_count: int = 8
@export var spin_speed: float = 6.0

var direction = Vector2.RIGHT
var _age := 0.0
var _done := false

# Track spawned pebbles so they despawn if this rock (or parent) is removed
var spawned_pebbles: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _exit_tree() -> void:
	# Automatically clean up any remaining pebbles spawned by this rock
	despawn_all_pebbles()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	rotation += spin_speed * delta
	_age += delta
	if _age >= split_time:
		split()

func split() -> void:
	if _done:
		return
	_done = true
	# Star pattern: evenly spaced directions, one of them pointing along the rock's travel
	var base_angle = direction.angle()
	for i in pebble_count:
		var dir = Vector2.RIGHT.rotated(base_angle + TAU * i / pebble_count)
		var p = pebble_scene.instantiate()
		p.global_position = global_position
		p.direction = dir
		p.rotation = dir.angle()
		
		# Track pebble and automatically untrack when it destroys itself
		spawned_pebbles.append(p)
		p.tree_exited.connect(func(): spawned_pebbles.erase(p))
		
		get_tree().current_scene.add_child.call_deferred(p)
	
	# Note: Do not call despawn_all_pebbles() here! 
	# queue_free() will wait until node tree exit, so _exit_tree() handles cleanup if interrupted.

func _on_body_entered(body: Node2D) -> void:
	if _done:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_done = true
	queue_free()

func despawn_all_pebbles() -> void:
	for pebble in spawned_pebbles:
		if is_instance_valid(pebble):
			pebble.queue_free()
	spawned_pebbles.clear()
