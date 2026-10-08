extends StaticBody2D

@export var rock_scene: PackedScene = preload("res://Scenes/rock_bullet_new.tscn")
@export var coin_scene: PackedScene = preload("res://Scenes/Coin.tscn")
@export var coin_drop_count: int = 3
@export var coin_drop_radius: float = 12.0
@export var max_health: int = 60
@export var throw_interval: float = 6.0
@export var throw_pose_time: float = 0.3

@onready var sprite: Sprite2D = $Sprite2D
@onready var hand: Marker2D = $Hand
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSFX
@onready var throw_timer: Timer = $ThrowTimer

@export var idle_texture: Texture2D
@export var throw_texture: Texture2D

var current_health: int
var is_dead: bool = false
var target: Node2D
var room: Room

func _ready() -> void:
	current_health = max_health
	target = get_tree().get_first_node_in_group("player")
	room = _find_room()
	throw_timer.wait_time = throw_interval
	throw_timer.timeout.connect(throw_rock)
	# Stagger the first throw so trolls in the same room don't throw in sync
	throw_timer.start(randf_range(1.0, min(throw_interval, 4.0)))

func _process(_delta: float) -> void:
	if is_instance_valid(target):
		# The sprite faces left; turn toward the player
		sprite.flip_h = target.global_position.x > global_position.x
		hand.position.x = absf(hand.position.x) * (1 if sprite.flip_h else -1)

func throw_rock() -> void:
	if not is_instance_valid(target) or rock_scene == null:
		return
	# Only attack while the player is in this troll's room
	if room and not room.has_point(target.global_position):
		return
	var rock = rock_scene.instantiate()
	var dir = (target.global_position - hand.global_position).normalized()
	rock.global_position = hand.global_position
	rock.direction = dir
	get_tree().current_scene.add_child(rock)
	show_throw_pose()

func show_throw_pose() -> void:
	sprite.texture = throw_texture
	await get_tree().create_timer(throw_pose_time).timeout
	if not is_dead:
		sprite.texture = idle_texture

func take_damage(amount: int) -> void:
	current_health -= amount
	flash_red()
	if hurt_sfx:
		hurt_sfx.pitch_scale = randf_range(0.9, 1.1)
		hurt_sfx.play()
	if current_health <= 0:
		die()

func flash_red() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	drop_coins()
	queue_free()

func drop_coins() -> void:
	if coin_scene == null:
		return
	for i in coin_drop_count:
		var coin = coin_scene.instantiate()
		var offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(4.0, coin_drop_radius)
		coin.global_position = global_position + offset
		# Deferred because die() usually runs inside a physics callback (bullet hit)
		get_tree().current_scene.add_child.call_deferred(coin)

func _find_room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node
