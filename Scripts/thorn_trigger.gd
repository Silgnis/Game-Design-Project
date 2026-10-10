extends Area2D
class_name TrapTrigger

@export var trigger_once: bool = true

var _triggered := false
var room: Room

func _ready() -> void:
	room = _find_room()
	body_exited.connect(_on_body_exited)

func _on_body_exited(body: Node2D) -> void:
	if _triggered and trigger_once:
		return
	
	if body is Player:
		_triggered = true
		if is_instance_valid(room):
			room.lock_room()

# Automatically finds the Room node this trigger is placed inside
func _find_room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room
