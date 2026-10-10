extends CanvasLayer
class_name PlayerUI

const FULL_HEART = preload("res://Resources/Custom Assets/heart.png")
const HALF_HEART = preload("res://Resources/Custom Assets/half heart.png")
const EMPTY_HEART = preload("res://Resources/Custom Assets/empty heart.png")
const HEALTH_PER_HEART = 2

@onready var hearts: Array[Node] = $Hearts.get_children()
@onready var coin_label: Label = $Coins/CoinLabel
@onready var dash_icon: TextureProgressBar = %DashIcon
@onready var myling_icon: TextureProgressBar = %MylingIcon

const ABILITY_READY_TINT = Color(1, 1, 1, 1)
const ABILITY_CHARGING_TINT = Color(0.55, 0.75, 1, 1)
const DASH_ICON_SCALE = Vector2(5, 5)
const MYLING_ICON_SCALE = Vector2(7, 7)

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

# progress goes from 0 (just used) to 1 (ready)
func update_dash(progress: float) -> void:
	_update_ability(dash_icon, progress, DASH_ICON_SCALE)

func update_myling(progress: float) -> void:
	_update_ability(myling_icon, progress, MYLING_ICON_SCALE)

func _update_ability(icon: TextureProgressBar, progress: float, base_scale: Vector2) -> void:
	var was_ready = icon.value >= icon.max_value
	icon.value = progress * icon.max_value
	var is_ready = icon.value >= icon.max_value
	icon.tint_progress = ABILITY_READY_TINT if is_ready else ABILITY_CHARGING_TINT

	# Small pop when the ability comes back
	if is_ready and not was_ready:
		icon.scale = base_scale * 1.3
		create_tween().tween_property(icon, "scale", base_scale, 0.15)
