extends Control
@export var paused = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause()
	
func _on_resume_pressed() -> void:
	pause()

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func pause():
	if paused == true:
		self.hide()
		get_tree().paused = false
		paused = false
	elif paused == false:
		self.show()
		get_tree().paused = true
		paused = true
