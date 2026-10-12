extends StaticBody2D
class_name LockedGate

@export var required_item_id: String = "boss_key"

@onready var interact_area: Area2D = $InteractArea
var player_in_range: Player = null

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		print("Interact button pressed while in range!")
		try_open()

func try_open() -> void:
	if GameManager.has_item(required_item_id):
		queue_free()
	else:
		print("Gate is locked. You need the item: ", required_item_id)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = body

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		print("Player left gate range!")
		player_in_range = null
