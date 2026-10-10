extends Area2D
class_name DialogueTrigger

# Starts a conversation when the player walks into this area. Give it a CollisionShape2D
# for the area and fill in the speaker and lines in the Inspector.

@export var speaker := ""
@export_multiline var lines: Array[String] = []
@export var one_shot := true   # only plays the first time the player walks in

var _played := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # Player
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or Dialogue.is_open():
		return
	if one_shot and _played:
		return
	_played = true
	Dialogue.say(speaker, lines)
