extends Sprite2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var shooting_dir = (mouse_pos - global_position).normalized()
	var direction = shooting_dir
	var angle = shooting_dir.angle()
	rotation = angle
	if  angle > 0.5*PI or angle < -0.5*PI:
		flip_v = true
	if  angle < 0.5*PI and angle > -0.5*PI:
		flip_v = false
