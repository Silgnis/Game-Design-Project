extends StaticBody2D
class_name ThornDoor

@export var damage_amount: int = 10

@onready var sprite: Sprite2D = $Sprite2D
@onready var solid_collision: CollisionShape2D = $SolidCollision
@onready var damage_area: Area2D = $DamageArea
@onready var hazard_collision: CollisionShape2D = $DamageArea/HazardCollision
@onready var timer: Timer = $Timer

# Array to keep track of bodies currently inside the damage area
var bodies_in_damage_area: Array[Node2D] = []
var is_locked_open: bool = false

func _ready() -> void:
	# Connect damage area signal
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	open_door()

func close_door() -> void:
	if is_locked_open:
		return
	# Enable physical barrier AND damage trigger
	solid_collision.set_deferred("disabled", false)
	hazard_collision.set_deferred("disabled", false)
	show()

func open_door() -> void:
	# Disable both collision shapes and hide
	solid_collision.set_deferred("disabled", true)
	hazard_collision.set_deferred("disabled", true)
	hide()

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_amount)
		
		bodies_in_damage_area.append(body)
		
		# Apply immediate damage on first touch
		body.take_damage(damage_amount)
		
		# Start the repeating 1-second timer if it's not already running
		if timer.is_stopped():
			timer.start()

func _on_damage_area_body_exited(body: Node2D) -> void:
	if body in bodies_in_damage_area:
		bodies_in_damage_area.erase(body)
		
		if bodies_in_damage_area.is_empty():
			timer.stop()

func _on_timer_timeout() -> void:
	# Deal damage every second to all bodies standing inside
	for body in bodies_in_damage_area:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(damage_amount)
