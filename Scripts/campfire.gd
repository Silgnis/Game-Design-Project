extends Area2D

@export var damage_amount: int = 10

@onready var timer: Timer = $Timer

# Array to keep track of bodies currently inside the campfire
var bodies_in_fire: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		bodies_in_fire.append(body)
		
		# Apply immediate damage on first touch
		body.take_damage(damage_amount)
		
		# Start the repeating 1-second timer if it's not already running
		if timer.is_stopped():
			timer.start()

func _on_body_exited(body: Node2D) -> void:
	if body in bodies_in_fire:
		bodies_in_fire.erase(body)
		
		if bodies_in_fire.is_empty():
			timer.stop()

func _on_timer_timeout() -> void:
	# Deal damage every second to all bodies standing inside
	for body in bodies_in_fire:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(damage_amount)
