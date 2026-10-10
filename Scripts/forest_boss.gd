extends EnemyBase
class_name ForestBoss

@export var boss_name: String = "Forest Elemental"
@export var start_delay: float = 1.5
@export var time_between_attacks: float = 1.2
@export var telegraph_time: float = 0.5 # Wind-up before an attack so the player can react

@export_group("Pinecones")
@export var pinecone_scene: PackedScene = preload("res://Scenes/Boss/pinecone.tscn")
@export var pinecone_volleys: int = 3
@export var pinecones_per_volley: int = 4
@export var pinecone_spread_degrees: float = 100.0
@export var pinecone_volley_delay: float = 0.8

@export_group("Tree Circle")
@export var tree_circle_scene: PackedScene = preload("res://Scenes/Boss/tree_circle.tscn")
@export var second_circle_delay: float = 0.8 # When a tier casts 2 circles, the 2nd lands on the player this much later
# With 2 circles in a row the rings close this much faster
@export var multi_circle_close_faster_by: float = 0.2
# Angry phase 2 opens with a tree circle whose bushes take over this long after the first tree
@export var angry_opener_fill_time: float = 1.5

@export_group("Furious Trap")
# Furious phase 2 opens by trapping the player in a ring of breakable trees, then fires
# buffed pinecones that fly over the trees. Breaking a tree out is the only real escape.
@export var trap_pinecone_delay: float = 1.5
@export var trap_volleys: int = 2
@export var trap_pinecones_per_volley: int = 5

@export_group("AOE")
# Phase 2 only. Thorns creep in from the edges while the boss charges; the only way to stop
# the blast is to get close and use the myling on it, which breaks the charge and stuns it.
@export var thorn_field_scene: PackedScene = preload("res://Scenes/Boss/thorn_field.tscn")
@export var aoe_charge_time: float = 2.0 # Shadow grows from the boss to the edge in this time, then it blasts
@export var aoe_cooldown: float = 15.0 # Minimum time after an AOE ends (blast or broken) before the next
@export var aoe_damage: int = 3 # Half hearts; can't be dashed through
@export var stun_time: float = 3.0
@export var stun_damage_mult: float = 2.0

@export_group("Myling")
# Outside the AOE charge, the myling just slows the boss and everything it has thrown
@export_range(0.1, 1.0) var myling_slow_factor: float = 0.5

@export_group("Phase 2")
@export_range(0.0, 1.0) var phase_two_health: float = 0.5 # Fraction of max health that starts phase 2
# Kill tiers: below angry_kills is calm (few or no kills), then angry, then furious
@export var angry_kills: int = 2
@export var furious_kills: int = 4
# Per tier [calm, angry, furious]: multiplier on wait times, and extra pinecones per volley
@export var tier_pace: Array[float] = [0.9, 0.8, 0.65]
@export var tier_extra_pinecones: Array[int] = [0, 1, 2]
@export var tier_tree_circles: Array[int] = [1, 1, 2]
@export var debug_kills_override: int = -1 # Set >= 0 in the test arena to try each tier
# Every enemy the player kills is a ghost, so each kill is a soul that never gets its
# eternal rest. {kills} is replaced with that number. spared_lines is used for 0 kills.
@export_multiline var spared_lines: Array[String] = [
	"You walked through my forest... and destroyed none of its spirits.",
	"Thanks to you, they will all find their eternal rest.",
	"But this is as far as you go, stranger.",
]
@export_multiline var calm_lines: Array[String] = [
	"So you made it this far...",
	"{kills} of my spirits will never find their eternal rest because of you.",
	"Few... but I do not forgive.",
]
@export_multiline var angry_lines: Array[String] = [
	"You really annoyed me!",
	"You destroyed {kills} souls. They will never find their eternal rest!",
	"And I'm going to make you pay for it!",
]
@export_multiline var furious_lines: Array[String] = [
	"ENOUGH!",
	"{kills} souls... torn apart before they could find their peace.",
	"The whole forest will tear you apart!",
]

const PHASE_TWO_TINT = Color(0.75, 0.6, 0.65)
const PHASE_TWO_EYES = Color(1, 0.2, 0.15)
const PHASE_TWO_BAR = Color(0.75, 0.25, 0.2)
const SLOW_TINT = Color(0.6, 0.85, 1.3)
const STUN_TINT = Color(0.55, 0.55, 0.6)
const CHARGE_TINT = Color(1.8, 0.6, 0.5)

@onready var sprite: Sprite2D = $Sprite2D
@onready var throw_point: Marker2D = $ThrowPoint
@onready var boss_ui: CanvasLayer = $BossUI
@onready var health_bar: ProgressBar = %HealthBar
@onready var name_label: Label = %BossName

var target: Node2D
var last_attack: Callable
var spawned_projectiles: Array[Node2D] = []

var phase := 1
var is_transitioning := false
var kill_tier := 0
var pace := 1.0 # Multiplies attack wait times; lower = faster
var base_tint := Color.WHITE
var _telegraph_tween: Tween
var _wait_timers: Array[Timer] = []

var time_scale := 1.0 # Below 1 while slowed by the myling
var is_charging_aoe := false
var is_stunned := false
var _slow_id := 0
var _aoe_field: Node2D
var _charge_tweens: Array[Tween] = []
var _flash: ColorRect
var aoe_cooldown_left := 0.0

func _init() -> void:
	enemy_id = "forest_boss"
	max_health = 2000
	stage_coin_drops = [20]

func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return

	target = get_tree().get_first_node_in_group("player")
	name_label.text = boss_name
	health_bar.max_value = max_health
	health_bar.value = current_health

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_ui.add_child(_flash)

	_attack_loop()

func _process(delta: float) -> void:
	if aoe_cooldown_left > 0.0:
		aoe_cooldown_left -= delta * time_scale

func _exit_tree() -> void:
	despawn_projectiles()

func take_damage(amount: int) -> void:
	if is_transitioning or is_dead:
		return
	# Phase 1 can't be skipped with one big hit
	if phase == 1:
		amount = mini(amount, current_health - _phase_two_hp())
	if is_stunned:
		amount = int(amount * stun_damage_mult)
	super.take_damage(amount)
	health_bar.value = max(current_health, 0)

	if phase == 1 and current_health <= _phase_two_hp():
		_start_phase_two()

# Myling: breaks the AOE if it's charging, otherwise slows the boss and its attacks
func freeze(duration: float) -> void:
	if is_dead or is_transitioning or is_stunned:
		return
	if is_charging_aoe:
		break_aoe()
	else:
		slow_down(duration)

func slow_down(duration: float) -> void:
	_slow_id += 1
	set_time_scale(myling_slow_factor)
	sprite.self_modulate = SLOW_TINT
	get_tree().create_timer(duration).timeout.connect(_on_slow_timeout.bind(_slow_id))

func _on_slow_timeout(id: int) -> void:
	if id != _slow_id or is_dead:
		return
	end_slow()

func end_slow() -> void:
	_slow_id += 1
	set_time_scale(1.0)
	sprite.self_modulate = Color.WHITE

# Stretches running waits/tweens and slows every projectile the boss has out
func set_time_scale(value: float) -> void:
	for timer in _wait_timers:
		if timer.time_left > 0.0:
			timer.start(timer.time_left * time_scale / value)
	time_scale = value
	for tween in [_telegraph_tween] + _charge_tweens:
		if tween and tween.is_valid():
			tween.set_speed_scale(value)
	for proj in spawned_projectiles:
		if is_instance_valid(proj) and proj.has_method("set_time_scale"):
			proj.set_time_scale(value)

func die() -> void:
	if is_dead:
		return
	cancel_waits()
	despawn_projectiles()
	boss_ui.hide()
	super.die()

func _phase_two_hp() -> int:
	return int(max_health * phase_two_health)

# --- Attack loop ---

func _attack_loop() -> void:
	await wait(start_delay)
	while not is_dead:
		await _pick_attack().call()
		if is_dead:
			return
		await wait(time_between_attacks * pace)

func _pick_attack() -> Callable:
	var attacks: Array[Callable] = [attack_pinecones, attack_tree_circle]
	if phase == 2 and aoe_cooldown_left <= 0.0:
		attacks.append(attack_aoe)
	# Don't repeat the same attack twice in a row
	if attacks.size() > 1 and last_attack.is_valid():
		attacks.erase(last_attack)
	last_attack = attacks.pick_random()
	return last_attack

# Each wait gets its own child Timer. Freeing the timers (cancel_waits) drops every
# coroutine waiting on them, which is how a phase change interrupts the current attack.
func wait(seconds: float) -> void:
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	_wait_timers.append(timer)
	timer.start(seconds / time_scale)
	await timer.timeout
	_wait_timers.erase(timer)
	timer.queue_free()

func cancel_waits() -> void:
	for timer in _wait_timers:
		timer.queue_free()
	_wait_timers.clear()

func telegraph() -> void:
	_telegraph_tween = create_tween().set_speed_scale(time_scale)
	_telegraph_tween.tween_property(sprite, "modulate", Color(0.6, 1.6, 0.6), telegraph_time * pace)
	_telegraph_tween.parallel().tween_property(sprite, "scale", Vector2(1.1, 0.9), telegraph_time * pace)
	await wait(telegraph_time * pace)

	var release = create_tween()
	release.tween_property(sprite, "modulate", base_tint, 0.15)
	release.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.15)

# --- Phase 2 transition ---

func _start_phase_two() -> void:
	is_transitioning = true
	cancel_waits()
	despawn_projectiles()
	if _telegraph_tween:
		_telegraph_tween.kill()
	end_slow()
	sprite.scale = Vector2.ONE

	var kills = _count_kills()
	kill_tier = 2 if kills >= furious_kills else (1 if kills >= angry_kills else 0)

	# Short rage shake before talking
	var shake = create_tween()
	for i in 8:
		shake.tween_property(sprite, "position:x", 2.0 if i % 2 == 0 else -2.0, 0.05)
	shake.tween_property(sprite, "position:x", 0.0, 0.05)
	sprite.modulate = Color(1.6, 1.6, 1.6)
	create_tween().tween_property(sprite, "modulate", base_tint, 0.45)
	await wait(0.6)

	var lines = [calm_lines, angry_lines, furious_lines][kill_tier]
	if kills == 0:
		lines = spared_lines
	await Dialogue.say(boss_name, lines.map(func(line): return line.format({"kills": kills})))
	if is_dead:
		return

	_enter_phase_two()
	is_transitioning = false

	# Calm continues straight away; angry opens with a tree circle; furious with the trap
	match kill_tier:
		1:
			last_attack = attack_tree_circle
			await attack_tree_circle(angry_opener_fill_time)
		2:
			last_attack = attack_tree_circle
			await attack_tree_trap()
	_attack_loop()

func _enter_phase_two() -> void:
	phase = 2
	pace = tier_pace[kill_tier]
	pinecones_per_volley += tier_extra_pinecones[kill_tier]

	base_tint = PHASE_TWO_TINT
	create_tween().tween_property(sprite, "modulate", base_tint, 0.3)
	$Sprite2D/LeftEye.color = PHASE_TWO_EYES
	$Sprite2D/RightEye.color = PHASE_TWO_EYES

	var fill = health_bar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = PHASE_TWO_BAR
	health_bar.add_theme_stylebox_override("fill", fill)

func _count_kills() -> int:
	if debug_kills_override >= 0:
		return debug_kills_override
	return GameManager.get_total_kills()

# --- Attack: homing pinecones ---

func attack_pinecones() -> void:
	for volley in pinecone_volleys:
		await telegraph()
		if is_dead:
			return
		fire_pinecone_volley()
		await wait(pinecone_volley_delay * pace)

# count < 0 means the boss's current pinecones_per_volley
func fire_pinecone_volley(count: int = -1, buffed: bool = false) -> void:
	if not is_instance_valid(target) or pinecone_scene == null:
		return
	if count < 0:
		count = pinecones_per_volley

	var base_dir = (target.global_position - throw_point.global_position).normalized()
	var spread = deg_to_rad(pinecone_spread_degrees)
	for i in count:
		# Fan the volley out; the pinecones then curve back in from different angles
		var t = 0.5 if count == 1 else float(i) / (count - 1)
		var dir = base_dir.rotated(lerpf(-spread / 2, spread / 2, t))

		var pinecone = pinecone_scene.instantiate()
		pinecone.global_position = throw_point.global_position
		pinecone.direction = dir
		pinecone.target = target
		pinecone.buffed = buffed
		register_spawned_node(pinecone)
		get_tree().current_scene.add_child(pinecone)

# --- Attack: tree circle around the player ---

# All tree circles can be shot down. fill_time > 0 overrides how long until the bushes.
func attack_tree_circle(fill_time: float = -1.0) -> void:
	await telegraph()
	if is_dead or tree_circle_scene == null:
		return

	var circles = tier_tree_circles[kill_tier] if phase == 2 else 1
	# Each circle starts on the opposite side from the previous one: the 2nd ring's first
	# trees grow right where the 1st ring's gap was, so escaping through it runs into them
	var first_angle = randf() * TAU
	var circle = null
	for i in circles:
		if i > 0:
			await wait(second_circle_delay)
		var angle = first_angle + PI * i
		var faster_by = multi_circle_close_faster_by if circles > 1 else 0.0
		circle = spawn_tree_circle(false, true, faster_by, angle, fill_time)
	# Next attack starts once the last ring has closed; the bushes keep lingering on their own
	if circle:
		await wait(circle.close_time + circle.closed_hold)

func attack_tree_trap() -> void:
	var trap = spawn_tree_circle(true, true)
	if trap == null:
		return

	await wait(maxf(trap_pinecone_delay - telegraph_time * pace, 0.0))
	await telegraph()
	for volley in trap_volleys:
		fire_pinecone_volley(trap_pinecones_per_volley, true)
		await wait(pinecone_volley_delay * pace)

# instant: whole ring at once. breakable: player bullets can chop the trees down.
# fill_time > 0: time from the first tree to the bushes (closing + closed_hold)
func spawn_tree_circle(instant: bool = false, breakable: bool = false, close_faster_by: float = 0.0,
		start_angle: float = NAN, fill_time: float = -1.0) -> Node2D:
	if not is_instance_valid(target):
		return null
	var circle = tree_circle_scene.instantiate()
	circle.global_position = target.global_position
	circle.instant = instant
	circle.breakable = breakable
	circle.close_time = maxf(circle.close_time - close_faster_by, 0.1)
	if fill_time > 0.0:
		circle.close_time = maxf(fill_time - circle.closed_hold, 0.1)
	circle.start_angle = start_angle
	register_spawned_node(circle)
	get_tree().current_scene.add_child(circle)
	return circle

# --- Attack: AOE (phase 2) ---

func attack_aoe() -> void:
	if not is_instance_valid(target):
		return
	is_charging_aoe = true
	# The myling is the only counter, so it must be available
	if target.has_method("refill_myling"):
		target.refill_myling()

	_aoe_field = thorn_field_scene.instantiate()
	_aoe_field.close_time = aoe_charge_time
	_aoe_field.shadow_time = aoe_charge_time
	register_spawned_node(_aoe_field)
	# Inserted right before the boss so it draws underneath the boss and the player
	get_parent().add_child(_aoe_field)
	get_parent().move_child(_aoe_field, get_index())
	_aoe_field.global_position = global_position

	_start_charge_visuals()
	await wait(aoe_charge_time)

	# Nobody stopped it
	is_charging_aoe = false
	aoe_cooldown_left = aoe_cooldown
	_stop_charge_visuals()
	if is_instance_valid(_aoe_field):
		_aoe_field.retract()
	_flash.color.a = 0.8
	create_tween().tween_property(_flash, "color:a", 0.0, 0.4)
	if is_instance_valid(target):
		if target.has_method("take_unavoidable_damage"):
			target.take_unavoidable_damage(aoe_damage)
		else:
			target.take_damage(aoe_damage)
	await wait(0.8)

func break_aoe() -> void:
	is_charging_aoe = false
	aoe_cooldown_left = aoe_cooldown
	cancel_waits() # Drops the AOE coroutine and the attack loop with it
	end_slow()
	_stop_charge_visuals()
	if is_instance_valid(_aoe_field):
		_aoe_field.retract()
	_stun()

func _stun() -> void:
	is_stunned = true
	name_label.text = boss_name + " - STUNNED"
	sprite.self_modulate = STUN_TINT
	sprite.rotation = 0.15
	await wait(stun_time)
	if is_dead:
		return
	is_stunned = false
	name_label.text = boss_name
	sprite.self_modulate = Color.WHITE
	sprite.rotation = 0.0
	last_attack = attack_aoe
	_attack_loop()

func _start_charge_visuals() -> void:
	var pulse = create_tween().set_loops().set_speed_scale(time_scale)
	pulse.tween_property(sprite, "scale", Vector2(1.12, 0.92), 0.25)
	pulse.tween_property(sprite, "scale", Vector2.ONE, 0.25)
	var glow = create_tween().set_speed_scale(time_scale)
	glow.tween_property(sprite, "modulate", CHARGE_TINT, aoe_charge_time)
	_charge_tweens = [pulse, glow]

func _stop_charge_visuals() -> void:
	for tween in _charge_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_charge_tweens.clear()
	sprite.scale = Vector2.ONE
	sprite.modulate = base_tint

func register_spawned_node(node: Node2D) -> void:
	if time_scale != 1.0 and node.has_method("set_time_scale"):
		node.set_time_scale(time_scale)
	spawned_projectiles.append(node)
	node.tree_exited.connect(func(): spawned_projectiles.erase(node))

func despawn_projectiles() -> void:
	for proj in spawned_projectiles:
		if is_instance_valid(proj):
			proj.queue_free()
	spawned_projectiles.clear()
