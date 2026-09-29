extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")
@export var target: Node2D # Drag your Player node here in the editor, or acquire via group

@onready var muzzle: Marker2D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer

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
