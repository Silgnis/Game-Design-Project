extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/EnemyBullet.tscn")
@export var target: Node2D # Drag your Player node here in the editor, or acquire via group

@onready var muzzle: Marker2D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer

@export var max_health: int = 100
var current_health: int = max_health

func _ready() -> void:
	# Connect the timer's timeout signal to the shoot function
	shoot_timer.timeout.connect(shoot)

func _process(_delta: float) -> void:
	# Optionally rotate the turret to face the target
	if is_instance_valid(target):
		look_at(target.global_position)

func shoot() -> void:
	if bullet_scene == null:
		return
		
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	
	# Determine shooting direction (toward target or straight ahead)
	var shooting_dir: Vector2
	if is_instance_valid(target):
		shooting_dir = (target.global_position - muzzle.global_position).normalized()
	else:
		shooting_dir = Vector2.RIGHT.rotated(global_rotation)
	
	b.global_position = muzzle.global_position
	b.direction = shooting_dir
	b.rotation = shooting_dir.angle()
	
func take_damage(amount: int) -> void:
	current_health -= amount
	flash_red()
	
	if current_health <= 0:
		die()

func flash_red() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func die() -> void:
	queue_free()
