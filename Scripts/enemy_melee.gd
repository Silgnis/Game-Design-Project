extends EnemyBase
class_name MeleeEnemy

@export var move_speed: float = 40.0
@export var damage: int = 20

@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var target: Node2D

func _init() -> void:
	enemy_id = "melee_enemy"
	max_health = 80

func _ready() -> void:
	super._ready() # This will automatically call our overridden update_appearance()
	
	if is_queued_for_deletion():
		return
		
	target = get_tree().get_first_node_in_group("player")
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)
	
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)

# OVERRIDE for the animation in first stage
func update_appearance() -> void:
	if not animated_sprite:
		return
	
	print_debug(stage_index)
	var anim_name = "stage_" + str(stage_index)
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		print_debug("hey")
		# Fallback if a specific stage animation doesn't exist
		animated_sprite.play("default")

func _physics_process(delta: float) -> void:
	if is_dead or is_frozen or not is_instance_valid(target):
		return
		
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	
	# Optional: Flip the sprite based on movement direction
	if direction.x != 0:
		animated_sprite.flip_h = direction.x > 0
		
	move_and_slide()

func attack() -> void:
	if is_dead or is_frozen:
		return
	if is_instance_valid(target) and target.has_method("take_damage"):
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
