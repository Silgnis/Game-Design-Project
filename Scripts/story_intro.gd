extends Control

# Shown between the main menu and the game. The story strip starts dimmed; before each panel
# lights up, its part of the story plays in the dialogue box. Clicking skips the wait on a
# lit panel, Esc skips the whole intro (even in the middle of a line).

@export var strip: Texture2D = preload("res://Resources/Custom Assets/Story Strip.png")
@export var panel_time: float = 5.0 # How long a panel stays highlighted before the next beat
@export_file("*.tscn") var next_scene: String = "res://Scenes/Main.tscn"

# Panel rects inside Story Strip.png, in reading order
const PANELS = [
	Rect2(22, 30, 80, 102),
	Rect2(152, 30, 80, 102),
	Rect2(62, 140, 80, 102),
	Rect2(206, 140, 80, 102),
	Rect2(308, 28, 140, 214),
]
# What plays before each panel lights up: [speaker, [lines]] pairs. An empty speaker is narration.
const BEATS = [
	[
		["Father", ["Mmm, this stew is wonderful, dear."]],
		["Daughter", ["Can I go play by the river tomorrow?"]],
		["Mother", ["No. You're staying home, you have chores to do."]],
		["Father", ["Listen to your mother. I have to head out to work, I'll be back late."]],
	],
	[
		["Mother", [
			"We never had the money to have you baptized.",
			"And now the whole village looks at us like we're cursed. Like you're cursed.",
			"They'll never let you be one of them. They'll torment you your whole life.",
			"You don't deserve that, my love. Neither of us does.",
			"I'll set us both free. It's the only way.",
		]],
		["", ["Her mind broken, she reached for the knife."]],
	],
	[
		["Mother", [
			"I'll meet you somewhere better soon, my dear.",
		]],
	],
	[
		["", ["Believing they would meet again somewhere better, she followed her daughter."]],
	],
	[
		["", ["Some time later..."]],
		["Father", ["Hey, honey! I'm home!", "...Hello?", "What... what happened here?!"]],
		["Father", [
			"No... no, no... my girls...",
			"I'm so sorry. Both of you.",
			"I should have done more, back when there was still time.",
		]],
		["Father", [
			"...Is that you, sweetheart?",
			"Your soul can't rest. Not like this. You never got your baptism.",
			"You're the only innocent one in all of this.",
			"The least I can do is give you the eternal rest you deserve.",
			"There's a church past the forest. A holy place, where you can finally be at peace.",
			"We have a long way to go, so stick close to me, my dear.",
		]],
	],
]
const SEEN_TINT = Color(0.55, 0.55, 0.6)

@onready var board: Control = $Board
@onready var full: TextureRect = $Board/Full
@onready var frame: ReferenceRect = $Board/Frame
@onready var fade: ColorRect = $Fade

var _panels: Array[TextureRect] = []
var _index := -1
var _leaving := false
var _skip_hold := false

func _ready() -> void:
	# The dialogue box pauses the tree; the intro keeps running so Esc still works
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The whole strip stays hidden; only panels the story has reached are drawn
	full.hide()
	frame.hide()

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
	_run()

# Scale the strip up by a whole number so the pixel art stays crisp, and centre it
func _fit() -> void:
	var strip_size: Vector2 = strip.get_size()
	var fit = minf(size.x / strip_size.x, size.y / strip_size.y) * 0.95
	var s = maxf(floorf(fit), 1.0) if fit >= 1.0 else fit
	board.size = strip_size
	board.scale = Vector2(s, s)
	board.position = ((size - strip_size * s) / 2).floor()

func _run() -> void:
	fade.color.a = 1.0
	var fade_in = create_tween()
	fade_in.tween_property(fade, "color:a", 0.0, 0.6)
	await fade_in.finished

	for i in PANELS.size():
		for part in BEATS[i]:
			await Dialogue.say(part[0], part[1])
			if _leaving:
				return
		_show_panel(i)
		await _hold()
		if _leaving:
			return
	_finish()

# Waits panel_time, or less if the player clicks
func _hold() -> void:
	_skip_hold = false
	var waited := 0.0
	while waited < panel_time and not _skip_hold and not _leaving:
		await get_tree().process_frame
		waited += get_process_delta_time()

func _input(event: InputEvent) -> void:
	if _leaving or not _is_press(event):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
	elif not Dialogue.is_open():
		# While a line is showing, clicks belong to the dialogue box
		get_viewport().set_input_as_handled()
		_skip_hold = true

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

	var panel = _panels[i]
	panel.show()
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.95, 0.95)
	var pop = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(panel, "modulate", Color.WHITE, 0.35)
	pop.tween_property(panel, "scale", Vector2.ONE, 0.35)

	frame.show()
	frame.position = PANELS[i].position - Vector2(2, 2)
	frame.size = PANELS[i].size + Vector2(4, 4)

func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	Dialogue.close()
	var out = create_tween()
	out.tween_property(fade, "color:a", 1.0, 0.6)
	out.tween_callback(func(): get_tree().change_scene_to_file(next_scene))
