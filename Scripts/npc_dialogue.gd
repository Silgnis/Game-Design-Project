extends Area2D
class_name NPCDialogue

@export var speaker := ""
@export_multiline var lines: Array[String] = []

@onready var bubble: AnimatedSprite2D = $Bubble

var _player_near := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	bubble.animation_finished.connect(_on_bubble_finished)
	bubble.hide()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = true
	bubble.show()
	bubble.play("pop")

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = false
	bubble.play_backwards("pop")

func _on_bubble_finished() -> void:
	if not _player_near:
		bubble.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or Dialogue.is_open() or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	talk()

func talk() -> void:
	await Dialogue.say(speaker, lines)
