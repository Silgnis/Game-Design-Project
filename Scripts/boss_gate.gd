extends StaticBody2D
class_name LockedGate

const SPEAKER := "Myling"

@export var required_item_id: String = "boss_key"
@export_multiline var locked_line := "Seems like we need a key for this door. It looks pretty old."
@export_multiline var open_line := "One step closer."

@onready var interact_area: Area2D = $InteractArea
@onready var bubble: AnimatedSprite2D = $Bubble
var player_in_range: Player = null
var _room: Room
var _active := false

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	bubble.global_scale = Vector2.ONE
	bubble.hide()
	_room = _find_room()

func _process(_delta: float) -> void:
	var active := _room == null or _room.is_cleared
	if active == _active:
		return
	_active = active
	if _active:
		bubble.show()
		bubble.play("pop")
	else:
		bubble.hide()
	_update_hint()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range == null or not _active or Dialogue.is_open() or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	try_open()

func try_open() -> void:
	if GameManager.has_item(required_item_id):
		if player_in_range:
			player_in_range.player_ui.hide_interact_hint(self)
		Dialogue.say(SPEAKER, [open_line])
		queue_free()
	else:
		Dialogue.say(SPEAKER, [locked_line])

func _update_hint() -> void:
	if player_in_range == null:
		return
	if _active:
		player_in_range.player_ui.show_interact_hint(self)
	else:
		player_in_range.player_ui.hide_interact_hint(self)

func _find_room() -> Room:
	var node := get_parent()
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = body
		_update_hint()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.player_ui.hide_interact_hint(self)
		player_in_range = null
