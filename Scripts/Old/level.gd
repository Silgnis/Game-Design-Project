extends Node2D

func _ready() -> void:
	if NavigationManager.spawn_door_tag != null and NavigationManager.spawn_door_tag != "":
		_on_level_spawn(NavigationManager.spawn_door_tag)

func _on_level_spawn(destination_tag: String) -> void:
	var door_path = "Doors/Door_" + destination_tag
	var door = get_node_or_null(door_path) as Door
	
	if door != null:
		# WAIT ONE FRAME to ensure the Player's _ready() function has finished connecting
		await get_tree().process_frame 
		
		NavigationManager.trigger_player_spawn(door.spawn.global_position)
		NavigationManager.spawn_door_tag = null 
	else:
		print_debug("CRITICAL: Could not find door at exact path: ", door_path)
