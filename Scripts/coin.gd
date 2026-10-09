extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var value: int = 1

func _ready() -> void:
	animated_sprite_2d.play("spin")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.currency += value
		queue_free()
