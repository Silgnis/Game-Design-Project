extends Area2D
class_name Bullet

@export var SPEED = 400.0
var direction = Vector2.RIGHT

func _ready() -> void:
	await get_tree().create_timer(3.0).timeout #remove if no collision
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
