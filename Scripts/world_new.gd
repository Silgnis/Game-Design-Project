extends Node2D

# Rooms are instanced side by side; the camera stays still on the room the player is in
# and slides to the next one when the player walks across a room's edge.
@export var transition_time := 0.35

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var current_room: Room

func _ready() -> void:
	current_room = _room_at(player.global_position)
	if current_room:
		camera.global_position = current_room.get_global_bounds().get_center()

func _process(_delta: float) -> void:
	if current_room and current_room.has_point(player.global_position):
		return
	var room := _room_at(player.global_position)
	if room == null or room == current_room:
		return
	current_room = room
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", room.get_global_bounds().get_center(), transition_time)

func _room_at(point: Vector2) -> Room:
	for room in get_tree().get_nodes_in_group("rooms"):
		if room.has_point(point):
			return room
	return null
