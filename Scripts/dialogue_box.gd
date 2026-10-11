extends CanvasLayer

# Bottom-of-screen dialogue box, registered as the `Dialogue` autoload:
#     await Dialogue.say("Old Hunter", ["First line.", "Second line."])
# The game is paused while the box is open. Any key, click or controller button advances:
# the first press finishes a line that is still typing, the next one goes to the next line.

signal finished

@export var chars_per_second := 40.0
# Presses right after opening are ignored, so a click already in progress doesn't skip line one.
@export var open_grace_time := 0.2

const OPTION_COLOR := Color(0.93, 0.95, 0.88, 1)
const OPTION_DIM_COLOR := Color(0.56, 0.62, 0.5, 1)
const OPTION_FONT_SIZE := 28
const CHOICES_MARGIN := 24.0
const CHOICES_GAP := 16.0

@onready var box: Control = $Box
@onready var name_tab: Control = $Box/NameTab
@onready var name_label: Label = $Box/NameTab/Name
@onready var text_label: RichTextLabel = $Box/Text
@onready var arrow: Label = $Box/Arrow
@onready var choices: Control = $Box/Choices
@onready var choice_list: VBoxContainer = $Box/Choices/List

var _lines: Array[String] = []
var _index := 0
var _active := false
var _accepting_input := false
var _typing: Tween
var _arrow_blink: Tween
var _fade: Tween
var _box_rest_y := 0.0
var _options: Array[String] = []
var _hints: Array[String] = []
var _base_text := ""
var _choice := 0
var _picked := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	box.hide()
	choices.hide()
	_box_rest_y = box.position.y

func is_open() -> bool:
	return _active

func say(speaker: String, lines: Array) -> void:
	if _active or lines.is_empty():
		return
	_lines.assign(lines.map(func(line): return str(line)))
	_options.clear()
	_hints.clear()
	_open(speaker)
	await finished

func choose(speaker: String, text: String, options: Array, hints: Array = []) -> int:
	if _active or options.is_empty():
		return -1
	_base_text = text
	_lines.assign([text])
	_options.assign(options.map(func(option): return str(option)))
	_hints.assign(hints.map(func(hint): return str(hint)))
	_open(speaker)
	await finished
	return _picked

func _open(speaker: String) -> void:
	_active = true
	_index = 0
	_choice = 0
	_picked = -1
	get_tree().paused = true
	name_label.text = speaker
	name_tab.visible = speaker != ""

	if _fade:
		_fade.kill()
	if box.visible and box.modulate.a > 0.0:
		box.modulate.a = 1.0
		box.position.y = _box_rest_y
	else:
		box.show()
		box.modulate.a = 0.0
		box.position.y = _box_rest_y + 12
		var open := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		open.tween_property(box, "modulate:a", 1.0, 0.15)
		open.tween_property(box, "position:y", _box_rest_y, 0.15)
	_build_choices()
	if not _options.is_empty():
		_lines[0] = _choice_text()
	_show_line()

	_accepting_input = false
	get_tree().create_timer(open_grace_time, true).timeout.connect(func(): _accepting_input = _active)

func _show_line() -> void:
	_stop_arrow()
	text_label.text = _lines[_index]
	text_label.visible_characters = 0
	var count := text_label.get_total_character_count()
	_typing = create_tween()
	_typing.tween_property(text_label, "visible_characters", count, count / chars_per_second)
	_typing.finished.connect(_start_arrow)

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not _options.is_empty():
		_choice_input(event)
		return
	if not _is_button_press(event):
		return
	get_viewport().set_input_as_handled()
	if not _accepting_input:
		return
	if _finish_typing():
		return
	if _index < _lines.size() - 1:
		_index += 1
		_show_line()
	else:
		_close()

func _choice_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := _option_at(event.position)
		if hovered != -1:
			_select(hovered)
		return
	if not _is_button_press(event) and not (event is InputEventKey and event.echo and event.pressed):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("up", true) or event.is_action_pressed("ui_up", true):
		_select(wrapi(_choice - 1, 0, _options.size()))
		return
	if event.is_action_pressed("down", true) or event.is_action_pressed("ui_down", true):
		_select(wrapi(_choice + 1, 0, _options.size()))
		return
	if not _accepting_input or event.is_echo():
		return
	var confirm := event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if event.is_action_pressed("ui_cancel"):
		_select(_options.size() - 1)
		confirm = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked := _option_at(event.position)
		if clicked != -1:
			_select(clicked)
			confirm = true
	if _finish_typing() or not confirm:
		return
	_picked = _choice
	_close()

func _finish_typing() -> bool:
	if _typing and _typing.is_running():
		_typing.kill()
		text_label.visible_characters = -1
		_start_arrow()
		return true
	return false

func _build_choices() -> void:
	for row in choice_list.get_children():
		choice_list.remove_child(row)
		row.queue_free()
	choices.visible = not _options.is_empty()
	var font := text_label.get_theme_font("normal_font")
	for option in _options:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pointer := Label.new()
		pointer.text = "▶"
		pointer.custom_minimum_size.x = 22
		var label := Label.new()
		label.text = option
		for part in [pointer, label]:
			part.mouse_filter = Control.MOUSE_FILTER_IGNORE
			part.add_theme_font_override("font", font)
			part.add_theme_font_size_override("font_size", OPTION_FONT_SIZE)
			row.add_child(part)
		choice_list.add_child(row)
	_place_choices()
	_select(0)

func _place_choices() -> void:
	choices.size = choices.get_combined_minimum_size()
	choices.position = Vector2(box.size.x - CHOICES_MARGIN - choices.size.x, -CHOICES_GAP - choices.size.y)

func _select(index: int) -> void:
	var changed := index != _choice
	_choice = index
	for i in choice_list.get_child_count():
		var row := choice_list.get_child(i)
		var selected := i == index
		row.get_child(0).modulate.a = 1.0 if selected else 0.0
		row.get_child(1).add_theme_color_override("font_color", OPTION_COLOR if selected else OPTION_DIM_COLOR)
	if changed and not _hints.is_empty():
		if _typing:
			_typing.kill()
		text_label.text = _choice_text()
		text_label.visible_characters = -1

func _choice_text() -> String:
	if _choice < _hints.size() and _hints[_choice] != "":
		return _hints[_choice]
	return _base_text

func _option_at(screen_pos: Vector2) -> int:
	if not choices.visible:
		return -1
	for i in choice_list.get_child_count():
		if (choice_list.get_child(i) as Control).get_global_rect().has_point(screen_pos):
			return i
	return -1

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
	_active = false
	finished.emit()
	if _active:
		return
	choices.hide()
	_fade = create_tween()
	_fade.tween_property(box, "modulate:a", 0.0, 0.12)
	await _fade.finished
	if _active:
		return
	box.hide()
	# The player polls the Shoot action, so stay paused until the closing click is released;
	# otherwise that click would fire the gun the moment the game resumes.
	while Input.is_action_pressed("Shoot"):
		await get_tree().process_frame
	if not _active:
		get_tree().paused = false

func _start_arrow() -> void:
	if not _options.is_empty():
		return
	arrow.show()
	_arrow_blink = create_tween().set_loops()
	_arrow_blink.tween_property(arrow, "modulate:a", 0.0, 0.0).set_delay(0.4)
	_arrow_blink.tween_property(arrow, "modulate:a", 1.0, 0.0).set_delay(0.4)

func _stop_arrow() -> void:
	if _arrow_blink:
		_arrow_blink.kill()
	arrow.hide()
	arrow.modulate.a = 1.0
