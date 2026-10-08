extends player

# The rifle flips itself when aiming left (see gun.gd); the body follows it
@onready var rifle: Sprite2D = get_node_or_null("Gun/rifle")

func _process(_delta: float) -> void:
	if rifle:
		animated_sprite_2d.flip_h = rifle.flip_v
	else:
		animated_sprite_2d.flip_h = get_global_mouse_position().x < global_position.x
