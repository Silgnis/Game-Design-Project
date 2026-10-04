extends CharacterBody2D

@export var target: Node2D          
@export var move_speed: float = 40.0
@export var max_health: int = 80
@export var damage: int = 20
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSFX
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
var current_health: int

func _ready() -> void:
	current_health = max_health
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	pass

func attack() -> void:
	if is_instance_valid(target):
		target.take_damage(damage)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == target:
		attack()
		attack_timer.start()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == target:
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	attack()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
func take_damage(amount: int) -> void:
	current_health -= amount
	flash_red()
	
	if hurt_sfx:
		# Randomize pitch slightly (0.9 to 1.1) so repeated hits don't sound repetitive
		hurt_sfx.pitch_scale = randf_range(0.9, 1.1)
		hurt_sfx.play()
	
	if current_health <= 0:
		die()

func flash_red() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func die() -> void:
	queue_free()
