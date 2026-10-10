extends CanvasLayer

# Bottom-of-screen dialogue box, registered as the `Dialogue` autoload:
#     await Dialogue.say("Old Hunter", ["First line.", "Second line."])
# The game is paused while the box is open. Any key, click or controller button advances:
# the first press finishes a line that is still typing, the next one goes to the next line.

signal finished

@export var chars_per_second := 40.0
# Presses right after opening are ignored, so a click already in progress doesn't skip line one.
@export var open_grace_time := 0.2

@onready var box: Control = $Box
@onready var name_tab: Control = $Box/NameTab
@onready var name_label: Label = $Box/NameTab/Name
@onready var text_label: RichTextLabel = $Box/Text
@onready var arrow: Label = $Box/Arrow

var _lines: Array[String] = []
var _index := 0
var _active := false
var _accepting_input := false
var _typing: Tween
var _arrow_blink: Tween
var _box_rest_y := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	box.hide()
	_box_rest_y = box.position.y

func is_open() -> bool:
	return _active

func say(speaker: String, lines: Array) -> void:
	if _active or lines.is_empty():
		return
	_active = true
	_lines.assign(lines.map(func(line): return str(line)))
	_index = 0
	get_tree().paused = true
	name_label.text = speaker
	name_tab.visible = speaker != ""

	box.show()
	box.modulate.a = 0.0
	box.position.y = _box_rest_y + 12
	var open := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	open.tween_property(box, "modulate:a", 1.0, 0.15)
	open.tween_property(box, "position:y", _box_rest_y, 0.15)
	_show_line()

	_accepting_input = false
	get_tree().create_timer(open_grace_time, true).timeout.connect(func(): _accepting_input = true)
	await finished

func _show_line() -> void:
	_stop_arrow()
	text_label.text = _lines[_index]
	text_label.visible_characters = 0
	var count := text_label.get_total_character_count()
	_typing = create_tween()
	_typing.tween_property(text_label, "visible_characters", count, count / chars_per_second)
	_typing.finished.connect(_start_arrow)

func _input(event: InputEvent) -> void:
	if not _active or not _is_button_press(event):
		return
	get_viewport().set_input_as_handled()
	if not _accepting_input:
		return
	if _typing and _typing.is_running():
		_typing.kill()
		text_label.visible_characters = -1
		_start_arrow()
	elif _index < _lines.size() - 1:
		_index += 1
		_show_line()
	else:
		_close()

func _is_button_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		var wheel: bool = event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
				MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]
		return event.pressed and not wheel
	if event is InputEventJoypadButton:
		return event.pressed
	return false

func _close() -> void:
	_accepting_input = false
	_stop_arrow()
	var fade := create_tween()
	fade.tween_property(box, "modulate:a", 0.0, 0.12)
	await fade.finished
	box.hide()
	# The player polls the Shoot action, so stay paused until the closing click is released;
	# otherwise that click would fire the gun the moment the game resumes.
	while Input.is_action_pressed("Shoot"):
		await get_tree().process_frame
	get_tree().paused = false
	_active = false
	finished.emit()

func _start_arrow() -> void:
	arrow.show()
	_arrow_blink = create_tween().set_loops()
	_arrow_blink.tween_property(arrow, "modulate:a", 0.0, 0.0).set_delay(0.4)
	_arrow_blink.tween_property(arrow, "modulate:a", 1.0, 0.0).set_delay(0.4)

func _stop_arrow() -> void:
	if _arrow_blink:
		_arrow_blink.kill()
	arrow.hide()
	arrow.modulate.a = 1.0
