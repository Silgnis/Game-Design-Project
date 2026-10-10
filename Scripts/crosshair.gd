extends Sprite2D

# Draws the crosshair at the mouse position and hides the system cursor while it exists.
# It keeps following the mouse while the game is paused (e.g. during dialogue).

func _ready() -> void:
	top_level = true          # ignore the gun's rotation and flip; position is in world space
	z_as_relative = false
	z_index = 100             # above trees, enemies and bullets
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
