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
			var tag := "sold" if GameManager.has_item(item.id) else "%d gold" % item.price
			options.append("%s - %s" % [item.display_name, tag])
			hints.append(item.description)
		options.append("Leave")
		var pick := await Dialogue.choose(speaker, menu_text, options, hints)
		if pick < 0 or pick >= items.size():
			return
		await _buy(items[pick])

func _buy(item: ShopItem) -> void:
	if GameManager.has_item(item.id):
		await Dialogue.say(speaker, [sold_out_text])
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.currency < item.price:
		await Dialogue.say(speaker, [too_poor_text])
		return
	player.currency -= item.price
	GameManager.add_item(item.id)
	await Dialogue.say(speaker, [thanks_text])
