extends Control

func _on_restart_pressed() -> void:
	self.hide()
	get_tree().paused = false
	var player = get_node("/root/Main/World/Player")
	GameManager.save_player_state(player.max_health, player.currency)
	NavigationManager.respawn_player()

func _on_quit_pressed() -> void:
	get_tree().quit()
