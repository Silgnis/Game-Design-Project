extends NPCDialogue
class_name ShopNPC

@export var items: Array[ShopItem] = []
@export var menu_text := "Here is what I have."
@export var thanks_text := "Pleasure doing business."
@export var too_poor_text := "You don't have enough gold for that."
@export var sold_out_text := "You already bought that one."

func talk() -> void:
	await Dialogue.say(speaker, lines)
	
	while true:
		var options: Array[String] = []
		var hints: Array[String] = []
		
		for item in items:
			# Only mark as "sold" if it's a one-time item and the player owns it
			var is_sold_out = not item.is_consumable and GameManager.has_item(item.id)
			var tag := "Sold" if is_sold_out else "%d gold" % item.price
			
			options.append("%s - %s" % [item.display_name, tag])
			hints.append(item.description)
			
		options.append("Leave")
		
		var pick := await Dialogue.choose(speaker, menu_text, options, hints)
		
		# If they picked "Leave" or pressed cancel
		if pick < 0 or pick >= items.size():
			return
			
		await _buy(items[pick])

func _buy(item: ShopItem) -> void:
	var is_sold_out = not item.is_consumable and GameManager.has_item(item.id)
	if is_sold_out:
		await Dialogue.say(speaker, [sold_out_text])
		return
		
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.currency < item.price:
		await Dialogue.say(speaker, [too_poor_text])
		return
		
	# Deduct currency
	player.currency -= item.price
	
	# Handle the item logic
	if not item.is_consumable:
		# Save permanent items to the GameManager
		GameManager.add_item(item.id)
	else:
		# Handle consumable effects immediately
		if item.id == "health_potion":
			player.current_health = player.max_health
			#player.current_health = min(player.current_health + 1, player.max_health)
			player.player_ui.update_hearts(player.current_health)
			
	await Dialogue.say(speaker, [thanks_text])
