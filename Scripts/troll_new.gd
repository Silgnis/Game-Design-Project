extends EnemyBase

@export var rock_scene: PackedScene = preload("res://Scenes/rock_bullet_new.tscn")
@export var throw_interval: float = 6.0
@export var throw_pose_time: float = 0.3

# Throw sprite per stage. The idle sprites come from stage_sprites in EnemyBase.
@export var stage_throw_textures: Array[Texture2D] = []

@export var is_frozen: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hand: Marker2D = $Hand
@onready var throw_timer: Timer = $ThrowTimer

# Array to track all active projectile instances (rocks and pebbles)
var spawned_projectiles: Array[Node2D] = []

var target: Node2D
var room: Room

# Array to track all active rocks thrown by this enemy
var spawned_rocks: Array[Node2D] = []

func _init() -> void:
	enemy_id = "stationary"
	max_health = 60

func _ready() -> void:
	super._ready()
	# The base class frees us if this enemy type is past its final stage
	if is_queued_for_deletion():
		return

	target = get_tree().get_first_node_in_group("player")
	room = _find_room()
	throw_timer.wait_time = throw_interval
	throw_timer.timeout.connect(throw_rock)
	# Stagger the first throw so trolls in the same room don't throw in sync
	throw_timer.start(randf_range(1.0, min(throw_interval, 4.0)))

func _exit_tree() -> void:
	# Triggered automatically when enemy is queue_free()'d or despawned
	despawn_all_rocks()

func _process(_delta: float) -> void:
	if is_instance_valid(target):
		# The sprite faces left; turn toward the player
		sprite.flip_h = target.global_position.x > global_position.x
		hand.position.x = absf(hand.position.x) * (1 if sprite.flip_h else -1)

func throw_rock() -> void:
	if is_dead or not is_instance_valid(target) or rock_scene == null:
		return
	if room and not room.has_point(target.global_position):
		return
		
	var rock = rock_scene.instantiate()
	var dir = (target.global_position - hand.global_position).normalized()
	rock.global_position = hand.global_position
	rock.direction = dir
	
	# Assign creator reference
	if "spawner_enemy" in rock:
		rock.spawner_enemy = self
	
	register_spawned_node(rock)
	
	get_tree().current_scene.add_child(rock)
	show_throw_pose()

func register_spawned_node(node: Node2D) -> void:
	spawned_projectiles.append(node)
	node.tree_exited.connect(func(): spawned_projectiles.erase(node))

func despawn_all_rocks() -> void:
	for proj in spawned_projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	spawned_projectiles.clear()

func show_throw_pose() -> void:
	if stage_index < stage_throw_textures.size() and stage_throw_textures[stage_index] != null:
		sprite.texture = stage_throw_textures[stage_index]
	await get_tree().create_timer(throw_pose_time).timeout
	if not is_dead:
		update_appearance()  # back to this stage's idle sprite

func _find_room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node
