extends CanvasLayer
class_name PlayerUI

const FULL_HEART = preload("res://Resources/Custom Assets/heart.png")
const HALF_HEART = preload("res://Resources/Custom Assets/half heart.png")
const EMPTY_HEART = preload("res://Resources/Custom Assets/empty heart.png")
const HEALTH_PER_HEART = 2

@onready var hearts: Array[Node] = $Hearts.get_children()
@onready var coin_label: Label = $Coins/CoinLabel

func update_hearts(current_health: int) -> void:
	for i in hearts.size():
		var heart: TextureRect = hearts[i]
		var heart_health = clamp(current_health - i * HEALTH_PER_HEART, 0, HEALTH_PER_HEART)

		if heart_health == HEALTH_PER_HEART:
			heart.texture = FULL_HEART
		elif heart_health > 0:
			heart.texture = HALF_HEART
		else:
			heart.texture = EMPTY_HEART

func update_coins(amount: int) -> void:
	coin_label.text = str(amount)
