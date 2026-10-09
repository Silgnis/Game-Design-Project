extends Sprite2D
class_name Gun

func _physics_process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var shooting_dir = (mouse_pos - global_position).normalized()
	var angle = shooting_dir.angle()
	
	# Rotate the gun toward the mouse
	rotation = angle
	
	# Flip the gun vertically when aiming left so it doesn't appear upside down
	if angle > 0.5 * PI or angle < -0.5 * PI:
		flip_v = true
	else:
		flip_v = false
