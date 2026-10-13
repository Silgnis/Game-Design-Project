extends Room

const SPEAKER := "Myling"
const INTRO_LINE := "Looks like a wolf. Get closer and then press space; I'll scare them so much they'll freeze, and then you can take care of them."
const STUN_LINE := "Now press space to stun the enemy. You'll be able to make quick work of them after."
const KILL_LINE := "Now kill the wolf."
const DEFEAT_LINE := "Odd. They didn't drop anything, and I still feel a certain presence... Let's try to go back and re-enter this room."
const BLOCKED_LINE := "Wait. Let's go back first and re-enter this room before continuing."
const GHOST_LINE := "I knew it. It became a ghost. Let's see what happens when you defeat them now."
const REWARD_LINES := ["That's what I thought... they now give some sort of currency. It seems that going back into rooms spawns the ghosts of the enemies.", "I still feel the presence of the ghost, so there might be an even bigger reward waiting for entering again. Let's keep going."]
const SOUL_LINE := "There it is. It's what's left of their soul. Defeat them one last time."
const FINAL_LINE := "I don't feel their presence anymore, but it seems like the forest doesn't like that. The rewards, though... Maybe it's worth it. We'll see."
const TUTORIAL_KILLS := 3

@export var wolf: EnemySpawner
@export var exit_door: ThornDoor
@export var exit_warning: Area2D
@export var reaction_delay := 0.6
@export var shake_duration := 0.8
@export var shake_strength := 4.0
@export var push_back_margin := 16.0
@export var push_back_time := 0.2

var _visit_lines_played := {}
var _tutorial_done := false
var _tutorial_abilities := [true, false, false]

func _ready() -> void:
	super._ready()
	exit_warning.body_entered.connect(_on_exit_warning_entered)
	_update_exit()

func on_player_entered() -> void:
	super.on_player_entered()
	_update_exit()
	var player := _player()
	if player == null:
		return
	if is_cleared:
		player.set_abilities(true, true, true)
	elif _in_tutorial():
		player.set_abilities(_tutorial_abilities[0], _tutorial_abilities[1], _tutorial_abilities[2])
	else:
		player.set_abilities(true, true, false)

func on_player_exited() -> void:
	super.on_player_exited()
	var player := _player()
	if player:
		player.set_abilities(player.can_dash, player.can_myling, true)

func lock_room() -> void:
	var was_cleared := is_cleared
	super.lock_room()
	_update_exit()
	if was_cleared:
		return
	var player := _player()
	if player and not _in_tutorial():
		player.set_abilities(true, true, true)
	var kills := _wolf_kills()
	if kills >= TUTORIAL_KILLS or _visit_lines_played.has(kills):
		return
	_visit_lines_played[kills] = true
	if kills == 0:
		_run_tutorial()
		return
	Dialogue.say(SPEAKER, [[INTRO_LINE, GHOST_LINE, SOUL_LINE][kills]])

func _run_tutorial() -> void:
	var player := _player()
	await Dialogue.say(SPEAKER, [INTRO_LINE])
	if player == null:
		return
	await player.dashed
	_tutorial_abilities = [true, true, false]
	player.set_abilities(true, true, false)
	await Dialogue.say(SPEAKER, [STUN_LINE])
	await player.myling_used
	player.set_abilities(true, true, true)
	_tutorial_done = true
	await Dialogue.say(SPEAKER, [KILL_LINE])

func _on_enemy_died() -> void:
	super._on_enemy_died()
	if active_enemies > 0:
		return
	var kills := _wolf_kills()
	if kills > TUTORIAL_KILLS:
		return
	await get_tree().create_timer(reaction_delay).timeout
	match kills:
		1:
			await Dialogue.say(SPEAKER, [DEFEAT_LINE])
		2:
			await Dialogue.say(SPEAKER, REWARD_LINES)
		TUTORIAL_KILLS:
			await _shake_screen()
			await Dialogue.say(SPEAKER, [FINAL_LINE])

func _unlock_room() -> void:
	super._unlock_room()
	_update_exit()

func _update_exit() -> void:
	if _wolf_kills() >= TUTORIAL_KILLS:
		return
	exit_door.is_locked_open = false
	exit_door.close_door()

func _shake_screen() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var tween := create_tween()
	var steps := int(shake_duration / 0.04)
	for i in steps:
		var strength := shake_strength * (1.0 - float(i) / steps)
		tween.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)
	await tween.finished

func _on_exit_warning_entered(body: Node2D) -> void:
	if not body is Player or Dialogue.is_open():
		return
	var kills := _wolf_kills()
	if is_cleared and kills > 0 and kills < TUTORIAL_KILLS:
		await Dialogue.say(SPEAKER, [BLOCKED_LINE])
		_push_back(body)

func _push_back(body: Node2D) -> void:
	var shape := exit_warning.get_node("CollisionShape2D") as CollisionShape2D
	var left := shape.global_position.x - (shape.shape as RectangleShape2D).size.x / 2.0
	var target_x := left - push_back_margin
	if body.global_position.x <= target_x:
		return
	create_tween().tween_property(body, "global_position:x", target_x, push_back_time)

func _in_tutorial() -> bool:
	return not _tutorial_done and _wolf_kills() == 0

func _player() -> Player:
	var node := get_parent()
	while node != null:
		if node.get("player") is Player:
			return node.get("player")
		node = node.get_parent()
	return null

func _wolf_kills() -> int:
	return GameManager.get_enemy_kills(wolf.enemy_id)
