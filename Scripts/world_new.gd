extends Node2D

@export var transition_time := 0.35

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var minimap: Minimap = get_node_or_null("HUD/Minimap")

var current_room: Room
var base_zoom: Vector2
var is_transitioning := false 
var rooms: Array = []

func _ready() -> void:
	rooms = get_tree().get_nodes_in_group("rooms")
	base_zoom = camera.zoom
	current_room = _room_at(player.global_position)
	if minimap:
		minimap.setup(rooms)
	if current_room:
		camera.global_position = current_room.get_global_bounds().get_center()
		camera.zoom = _zoom_for(current_room)
		# Spawn enemies in the initial starting room immediately
		current_room.on_player_entered()
		
		GameManager.play_room_music(current_room.music_type, 0.5)
		
		if minimap:
			minimap.set_current(current_room)

func _process(_delta: float) -> void:
	if is_transitioning:
		return
	
	if current_room and current_room.has_point(player.global_position):
		return

	var room := _room_at(player.global_position)
	if room == null or room == current_room:
		return
	
	# ROOM SWAP EVENTS
	var old_room := current_room
	current_room = room
	
	# TRIGGER CROSSFADE FOR NEW ROOM
	GameManager.play_room_music(current_room.music_type, transition_time)
	
	if minimap:
		minimap.set_current(room)
	current_room.on_player_entered()
	
	is_transitioning = true
	
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", room.get_global_bounds().get_center(), transition_time)
	tween.parallel().tween_property(camera, "zoom", _zoom_for(room), transition_time)
	
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

# A room scaled up by 1.5 needs the camera zoomed out by 1.5 to fit on screen
func _zoom_for(room: Room) -> Vector2:
	return base_zoom / room.global_scale.x
