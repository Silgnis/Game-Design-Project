extends Sprite2D
class_name Gun

# Half-width of the band around the holder's centre where the facing doesn't change, so
# aiming straight up/down (or across the player) doesn't make the sprite flip back and forth.
@export var facing_dead_zone := 6.0

# The node carrying the gun (the player). Facing is measured from its centre because that
# doesn't move when flipping; the rifle itself is shifted sideways when it flips, which used
# to push the mouse back across the line and flip it again every frame.
@onready var holder: Node2D = get_parent().get_parent() if get_parent().get_parent() is Node2D else get_parent()

func _physics_process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var shooting_dir = (mouse_pos - global_position).normalized()

	# Rotate the gun toward the mouse
	rotation = shooting_dir.angle()

	# Flip the gun vertically when aiming left so it doesn't appear upside down;
	# inside the dead zone keep whichever side it was already on
	var dx = mouse_pos.x - holder.global_position.x
	if dx < -facing_dead_zone:
		flip_v = true
	elif dx > facing_dead_zone:
		flip_v = false
