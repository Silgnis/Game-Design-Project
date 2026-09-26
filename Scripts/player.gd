extends CharacterBody2D
class_name player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var MOVE_SPEED = 100.0

var currency: int = 0

func _physics_process(_delta: float) -> void:
	movement()
	move_and_slide()

func movement() -> void:
	var direction = Input.get_vector("left","right","up","down")
	
	if direction != Vector2.ZERO:
		velocity = direction * MOVE_SPEED
		animated_sprite_2d.play("default")
	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()
