extends Area2D
class_name Bullet

@export var SPEED = 400.0
@export var damage: int = 10
var direction = Vector2.RIGHT

const SILVER_SHADER = preload("res://Resources/Shaders/silver.gdshader")
static var silver_material: ShaderMaterial

func _ready() -> void:
	if GameManager.has_item("silver_bullets"):
		if silver_material == null:
			silver_material = ShaderMaterial.new()
			silver_material.shader = SILVER_SHADER
		$Sprite2D.material = silver_material
	# Connect the Area2D collision signal programmatically
	body_entered.connect(_on_body_entered)
	
	# Despawn after 3 seconds if it hits nothing
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	# Check if the hit object has a damage method
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Destroy bullet on impact (with walls or characters)
	queue_free()
