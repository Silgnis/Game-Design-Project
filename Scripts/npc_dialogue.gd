extends Area2D
class_name NPCDialogue

@export var speaker := ""
@export_multiline var lines: Array[String] = []

@onready var bubble: AnimatedSprite2D = $Bubble

var _player_near := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("npc_dialogue")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	bubble.show()
	bubble.play("pop")

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = true
	bubble.play("pop")
	if body is Player:
		body.player_ui.show_interact_hint(self)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = false
	if body is Player:
		body.player_ui.hide_interact_hint(self)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or Dialogue.is_open() or not event.is_action_pressed("interact"):
		return
	if not _is_closest():
		return
	get_viewport().set_input_as_handled()
	talk()

func _is_closest() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return true
	var distance := global_position.distance_to(player.global_position)
	for other in get_tree().get_nodes_in_group("npc_dialogue"):
		if other != self and other._player_near and other.global_position.distance_to(player.global_position) < distance:
			return false
	return true

func talk() -> void:
	await Dialogue.say(speaker, lines)
