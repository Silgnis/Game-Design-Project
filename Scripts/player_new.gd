extends CharacterBody2D
class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep_sfx: AudioStreamPlayer2D = $FootstepSFX
@onready var gunshot_sfx: AudioStreamPlayer2D = $GunShotSFX
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSFX
@onready var player_ui: PlayerUI = $PlayerUI

# The rifle flips itself when aiming left (see gun.gd); the body follows it
@onready var rifle: Sprite2D = get_node_or_null("Gun/rifle")
@export var gun_flipped_offset_x: float = -10.0 # Adjust this value so that gun stays in player's hands
@export var bullet_scene = load("res://Scenes/bullet.tscn")

# Footstep Audio Configuration
@export var footstep_sounds: Array[AudioStream] = []
@export var footstep_frame: int = 2 # The frame index where a step occurs
var current_footstep_index: int = 0
var last_played_frame: int = -1

# Coins Audio Configuration
@export var coin_pickup_sound: AudioStream
@export var coin_spend_sound: AudioStream

@export var max_health: int = 6
@export var MOVE_SPEED = 100.0
@export var ACCELERATION = 2000.0
@export var DECELERATION = 1600.0

# Fire Rate Controls
@export var fire_rate: float = 0.25  # Time in seconds between shots
var shoot_cooldown_timer: float = 0.0

var is_initializing: bool = true
var current_health: int
var currency: int = 0:
	set(value):
		# Check if currency increased or decreased to play the appropriate SFX
		if not is_initializing and value != currency:
			if value > currency:
				play_coin_sound(coin_pickup_sound)
			elif value < currency:
				play_coin_sound(coin_spend_sound)
				
		currency = value
		if is_node_ready():
			player_ui.update_coins(currency)

func _ready() -> void:
	# Connect frame_changed signal to handle footsteps precisely when feet hit the ground
	if not animated_sprite_2d.frame_changed.is_connected(_on_animated_sprite_2d_frame_changed):
		animated_sprite_2d.frame_changed.connect(_on_animated_sprite_2d_frame_changed)

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
		
	is_initializing = false

func _on_spawn(position: Vector2):
	global_position = position
	
func _process(_delta: float) -> void:
	if rifle:
		animated_sprite_2d.flip_h = rifle.flip_v
		
		# Apply offset only when flipped left
		if rifle.flip_v:
			rifle.position.x = gun_flipped_offset_x
		else:
			rifle.position.x = 0.0 # Resets to default local position
	else:
		animated_sprite_2d.flip_h = get_global_mouse_position().x < global_position.x
	
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
		animated_sprite_2d.play("idle")

func _on_animated_sprite_2d_frame_changed() -> void:
	# Only execute when walking and actively moving
	if animated_sprite_2d.animation == "default" and velocity.length() > 10.0:
		var current_frame = animated_sprite_2d.frame
		
		# Check if we hit our target step frame and haven't already triggered on this exact loop
		if current_frame == footstep_frame and current_frame != last_played_frame:
			last_played_frame = current_frame
			
			if not footstep_sounds.is_empty():
				# Stop previous sound if it's still finishing to prevent overlap/layering
				if footstep_sfx.is_playing():
					footstep_sfx.stop()
				
				# Play the current sound from the list
				footstep_sfx.stream = footstep_sounds[current_footstep_index]
				footstep_sfx.pitch_scale = randf_range(0.96, 1.04)
				footstep_sfx.play()
				
				# Cycle to the next step index for the next impact
				current_footstep_index = (current_footstep_index + 1) % footstep_sounds.size()
		
		# Reset frame lock when animation advances past the step frame
		elif current_frame != footstep_frame:
			last_played_frame = -1
	else:
		# Reset when stopped or in idle state
		last_played_frame = -1
		
func play_coin_sound(stream_resource: AudioStream) -> void:
	if not stream_resource:
		return
		
	# Instantiate a dynamic audio player so sounds can overlap freely
	var dynamic_sfx := AudioStreamPlayer2D.new()
	add_child(dynamic_sfx)
	
	dynamic_sfx.stream = stream_resource
	# Slight pitch increase gives great feedback when collecting multiple coins quickly
	dynamic_sfx.pitch_scale = randf_range(0.95, 1.05)
	
	# Delete the node from memory once the sound finishes
	dynamic_sfx.finished.connect(dynamic_sfx.queue_free)
	
	dynamic_sfx.play()

func shoot():
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	
	var mouse_pos = get_global_mouse_position()
	var shooting_dir = (mouse_pos - global_position).normalized()
	b.global_position = global_position
	b.direction = shooting_dir
	b.rotation = shooting_dir.angle()
	
	if gunshot_sfx:
		gunshot_sfx.pitch_scale = randf_range(0.9, 1.1)
		gunshot_sfx.play()
	
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
