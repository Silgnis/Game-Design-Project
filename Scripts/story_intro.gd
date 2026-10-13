extends Control

# Shown between the main menu and the game. The story strip is shown dimmed, and its panels
# light up one at a time. Any click or key moves to the next panel, Esc skips the whole thing.

@export var strip: Texture2D = preload("res://Resources/Custom Assets/Story Strip.png")
@export var panel_time: float = 5.0
@export_file("*.tscn") var next_scene: String = "res://Scenes/Main.tscn"
# Presses right after a panel appears are ignored, so a double click doesn't skip two at once
@export var input_grace_time: float = 0.3

# Panel rects inside Story Strip.png, in reading order
const PANELS = [
	Rect2(22, 30, 80, 102),
	Rect2(152, 30, 80, 102),
	Rect2(62, 140, 80, 102),
	Rect2(206, 140, 80, 102),
	Rect2(308, 28, 140, 214),
]
const UNSEEN_TINT = Color(0.18, 0.18, 0.22)
const SEEN_TINT = Color(0.55, 0.55, 0.6)

@onready var board: Control = $Board
@onready var full: TextureRect = $Board/Full
@onready var frame: ReferenceRect = $Board/Frame
@onready var fade: ColorRect = $Fade

var _panels: Array[TextureRect] = []
var _index := -1
var _time := 0.0
var _leaving := false

func _ready() -> void:
	full.texture = strip
	full.size = strip.get_size()
	full.modulate = UNSEEN_TINT

	# One bright copy of each panel on top of the dimmed strip
	for rect in PANELS:
		var atlas = AtlasTexture.new()
		atlas.atlas = strip
		atlas.region = rect
		var panel = TextureRect.new()
		panel.texture = atlas
		panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.position = rect.position
		panel.size = rect.size
		panel.pivot_offset = rect.size / 2
		panel.hide()
		board.add_child(panel)
		_panels.append(panel)
	board.move_child(frame, -1)

	resized.connect(_fit)
	_fit()
	_show_panel(0)

	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, 0.6)

# Scale the strip up by a whole number so the pixel art stays crisp, and centre it
func _fit() -> void:
	var strip_size = strip.get_size()
	var fit = minf(size.x / strip_size.x, size.y / strip_size.y) * 0.95
	var s = maxf(floorf(fit), 1.0) if fit >= 1.0 else fit
	board.size = strip_size
	board.scale = Vector2(s, s)
	board.position = ((size - strip_size * s) / 2).floor()

func _process(delta: float) -> void:
	if _leaving:
		return
	_time += delta
	if _time >= panel_time:
		_next()

func _input(event: InputEvent) -> void:
	if _leaving or not _is_press(event):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		_finish()
	elif _time >= input_grace_time:
		_next()

func _is_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton or event is InputEventJoypadButton:
		return event.pressed
	return false

func _show_panel(i: int) -> void:
	if _index >= 0:
		create_tween().tween_property(_panels[_index], "modulate", SEEN_TINT, 0.4)
	_index = i
	_time = 0.0

	var panel = _panels[i]
	panel.show()
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.95, 0.95)
	var pop = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(panel, "modulate", Color.WHITE, 0.35)
	pop.tween_property(panel, "scale", Vector2.ONE, 0.35)

	frame.position = PANELS[i].position - Vector2(2, 2)
	frame.size = PANELS[i].size + Vector2(4, 4)

func _next() -> void:
	if _index < PANELS.size() - 1:
		_show_panel(_index + 1)
	else:
		_finish()

func _finish() -> void:
	_leaving = true
	var out = create_tween()
	out.tween_property(fade, "color:a", 1.0, 0.6)
	out.tween_callback(func(): get_tree().change_scene_to_file(next_scene))
