extends Node2D

@export var transition_time := 0.35

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var minimap: Minimap = get_node_or_null("HUD/Minimap")

var current_room: Room
var is_transitioning := false 
var rooms: Array = []

func _ready() -> void:
	rooms = get_tree().get_nodes_in_group("rooms")
	current_room = _room_at(player.global_position)
	if minimap:
		minimap.setup(rooms)
	if current_room:
		camera.global_position = current_room.get_global_bounds().get_center()
		# Spawn enemies in the initial starting room immediately
		current_room.on_player_entered()
		if minimap:
			minimap.set_current(current_room)

func _process(_delta: float) -> void:
	# Ignore checks while camera is sliding
	if is_transitioning:
		return
	
	if current_room and current_room.has_point(player.global_position):
		return

	var room := _room_at(player.global_position)
	if room == null or room == current_room:
		return

	# ROOM SWAP EVENTS
	
	# Store reference to the room being left behind
	var old_room := current_room
	
	# Update to new room and spawn its enemies immediately
	current_room = room
	if minimap:
		minimap.set_current(room)
	current_room.on_player_entered()
	
	is_transitioning = true
	
	# Animate camera to the new room center
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", room.get_global_bounds().get_center(), transition_time)
	
	# Despawn enemies in the old room only after camera slide is complete
	tween.finished.connect(func():
		is_transitioning = false
		if is_instance_valid(old_room):
			old_room.on_player_exited()
	)

func _room_at(point: Vector2) -> Room:
	for room in rooms:
		if room is Room and room.has_point(point):
			return room
	return null
