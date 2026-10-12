extends Area2D

@export var value: int = 1

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.current_health += value
		queue_free()
