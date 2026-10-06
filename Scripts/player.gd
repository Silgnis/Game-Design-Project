extends CharacterBody2D
class_name player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSFX
@onready var player_ui: PlayerUI = $PlayerUI
@export var bullet_scene = load("res://Scenes/bullet.tscn")

# Each hit costs 1 HP (half a heart), so 6 HP = 3 hearts
@export var max_health: int = 6
@export var MOVE_SPEED = 100.0

var current_health: int
var currency: int = 0

func _ready() -> void:
	current_health = max_health
	player_ui.update_hearts(current_health)
	# Connect door spawn signal as usual
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)
	# If returning from a checkpoint, place player at saved coordinates instead
	if NavigationManager.has_checkpoint:
		global_position = NavigationManager.current_checkpoint_pos

func _on_spawn(position: Vector2):
	global_position = position
	
func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("Shoot"):
		shoot()
	
	movement()
	move_and_slide()

func movement() -> void:
	var direction = Input.get_vector("left","right","up","down").normalized()
	
	if direction != Vector2.ZERO:
		velocity = direction * MOVE_SPEED
		animated_sprite_2d.play("default")
	else:
		velocity = Vector2.ZERO
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
	# Damage amount is ignored: every hit removes exactly half a heart
	current_health -= 1
	player_ui.update_hearts(current_health)
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
	current_health = max_health
	NavigationManager.respawn_player()
