extends CharacterBody2D
class_name player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var bullet_scene = load("res://Scenes/bullet.tscn")

@export var MOVE_SPEED = 100.0

var currency: int = 0

func _ready() -> void:
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)

func _on_spawn(position: Vector2):
	global_position = position
	
func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("Shoot"):
		shoot()
	
	movement()
	move_and_slide()

func movement() -> void:
	var direction = Input.get_vector("left","right","up","down").normalized()
	
	if direction != Vector2.ZERO:
		velocity = direction * MOVE_SPEED
		animated_sprite_2d.play("default")
	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()

func shoot():
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	
	var mouse_pos = get_global_mouse_position()
	var shooting_dir = (mouse_pos - global_position).normalized()
	b.global_position = global_position
	b.direction = shooting_dir
	b.rotation = shooting_dir.angle()
