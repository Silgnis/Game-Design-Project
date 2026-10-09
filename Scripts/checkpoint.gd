extends Area2D
class_name Checkpoint

@export var level_tag: String = "level_1" # Matches your match statements in NavigationManager
@export var activated_color: Color = Color.GREEN

var is_active: bool = false
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is player and not is_active:
		is_active = true
		NavigationManager.save_checkpoint(global_position, level_tag)
		
		if sprite:
			sprite.modulate = activated_color
