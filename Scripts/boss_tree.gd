extends StaticBody2D
class_name BossTree

# A pine the boss grows out of the ground. Solid like the room trees; when breakable,
# player bullets can chop it down (bullets call take_damage on any body they hit).

const TEXTURE = preload("res://Resources/Custom Assets/New Tileset.png")
const REGION = Rect2(282, 87, 25, 41) # Same pine as the room tiles
const SPRITE_OFFSET = Vector2(0, -13)
const BREAKABLE_TINT = Color(1.0, 0.8, 0.65) # Warmer so breakable trees read differently

var breakable := false
var health := 40
var collision_radius := 7.0
var sprout_time := 0.25

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _broken := false

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	_shape = CollisionShape2D.new()
	_shape.shape = CircleShape2D.new()
	_shape.shape.radius = collision_radius
	add_child(_shape)

	_sprite = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = TEXTURE
	atlas.region = REGION
	_sprite.texture = atlas
	_sprite.offset = SPRITE_OFFSET
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if breakable:
		_sprite.modulate = BREAKABLE_TINT
	add_child(_sprite)

	_sprite.scale = Vector2(0.6, 0.0)
	create_tween().tween_property(_sprite, "scale", Vector2.ONE, sprout_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func take_damage(amount: int) -> void:
	if not breakable or _broken:
		return
	health -= amount
	var flash = create_tween()
	flash.tween_property(_sprite, "modulate", Color.RED, 0.05)
	flash.tween_property(_sprite, "modulate", BREAKABLE_TINT, 0.1)
	if health <= 0:
		break_tree()

func break_tree() -> void:
	_broken = true
	# Deferred because this runs inside the bullet's physics callback
	_shape.set_deferred("disabled", true)
	var fall = create_tween()
	fall.tween_property(_sprite, "scale", Vector2(1.3, 0.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	fall.finished.connect(queue_free)
