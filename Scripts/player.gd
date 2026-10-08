extends CharacterBody2D
class_name player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSFX
@onready var player_ui: PlayerUI = $PlayerUI
@export var bullet_scene = load("res://Scenes/bullet.tscn")

@export var max_health: int = 6
@export var MOVE_SPEED = 100.0
@export var ACCELERATION = 2000.0
@export var DECELERATION = 1600.0

# Fire Rate Controls
@export var fire_rate: float = 0.25  # Time in seconds between shots
var shoot_cooldown_timer: float = 0.0

var current_health: int
var currency: int = 0:
	set(value):
		currency = value
		if is_node_ready():
			player_ui.update_coins(currency)

func _ready() -> void:
	# Load saved stats if they exist, otherwise use defaults
	if GameManager.saved_health != -1:
		current_health = GameManager.saved_health
		currency = GameManager.saved_currency
	else:
		current_health = max_health
		
	player_ui.update_hearts(current_health)
	player_ui.update_coins(currency)
	# Connect door spawn signal as usual
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)
	# If returning from a checkpoint, place player at saved coordinates instead
	if GameManager.has_checkpoint:
		global_position = GameManager.current_checkpoint_pos

func _on_spawn(position: Vector2):
	global_position = position
	
func _physics_process(delta: float) -> void:
	# Reduce timer toward zero
	if shoot_cooldown_timer > 0.0:
		shoot_cooldown_timer -= delta
		
	# Instant reset when button is released so rapid clicking fires immediately
	if Input.is_action_just_released("Shoot"):
		shoot_cooldown_timer = 0.0

	# Check if action is held down (is_action_pressed) and timer has elapsed
	if Input.is_action_pressed("Shoot") and shoot_cooldown_timer <= 0.0:
		shoot()
		shoot_cooldown_timer = fire_rate  # Reset cooldown
	
	movement(delta)
	move_and_slide()

func movement(delta: float) -> void:
	var direction = Input.get_vector("left","right","up","down").normalized()
	
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * MOVE_SPEED, ACCELERATION * delta)
		animated_sprite_2d.play("default")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)
		animated_sprite_2d.stop()

func shoot():
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	
	var mouse_pos = get_global_mouse_position()
	var shooting_dir = (mouse_pos - global_position).normalized()
	b.global_position = global_position
	b.direction = shooting_dir
	b.rotation = shooting_dir.angle()
	
func take_damage(_amount: int) -> void:
	current_health -= 1
	player_ui.update_hearts(current_health)
	flash_red()
	
	if hurt_sfx:
		hurt_sfx.pitch_scale = randf_range(0.9, 1.1)
		hurt_sfx.play()
	
	if current_health <= 0:
		die()

func flash_red() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func die() -> void:
	GameManager.save_player_state(max_health, currency)
	NavigationManager.respawn_player()
