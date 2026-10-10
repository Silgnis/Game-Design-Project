extends CanvasLayer
class_name PlayerUI

const FULL_HEART = preload("res://Resources/Custom Assets/heart.png")
const HALF_HEART = preload("res://Resources/Custom Assets/half heart.png")
const EMPTY_HEART = preload("res://Resources/Custom Assets/empty heart.png")
const HEALTH_PER_HEART = 2

@onready var hearts: Array[Node] = $Hearts.get_children()
@onready var coin_label: Label = $Coins/CoinLabel
@onready var dash_icon: TextureProgressBar = %DashIcon

const DASH_READY_TINT = Color(1, 1, 1, 1)
const DASH_CHARGING_TINT = Color(0.55, 0.75, 1, 1)
const DASH_ICON_SCALE = Vector2(5, 5)

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

# progress goes from 0 (just dashed) to 1 (ready)
func update_dash(progress: float) -> void:
	var was_ready = dash_icon.value >= dash_icon.max_value
	dash_icon.value = progress * dash_icon.max_value
	var is_ready = dash_icon.value >= dash_icon.max_value
	dash_icon.tint_progress = DASH_READY_TINT if is_ready else DASH_CHARGING_TINT

	# Small pop when the dash comes back
	if is_ready and not was_ready:
		dash_icon.scale = DASH_ICON_SCALE * 1.3
		create_tween().tween_property(dash_icon, "scale", DASH_ICON_SCALE, 0.15)
