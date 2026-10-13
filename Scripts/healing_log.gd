extends NPCDialogue
class_name HealingLog

func talk() -> void:
	await super.talk()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	player.current_health = player.max_health
	player.player_ui.update_hearts(player.current_health)
