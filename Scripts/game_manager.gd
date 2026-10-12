extends Node

# Player Stats
var saved_health: int = -1
var saved_currency: int = 0

# Checkpoints
var current_checkpoint_pos: Vector2 = Vector2.ZERO
var current_checkpoint_level: String = ""
var has_checkpoint: bool = false

# Progression / Kills
var enemy_kill_counts: Dictionary = {}

# Items
var owned_items: Array[String] = []

# Souls the player destroyed for good (killed every form of that enemy), as
# enemy_id -> enemy scene path. The boss reacts to the count and summons from these scenes.
var destroyed_souls: Dictionary = {}

# Music
enum MusicTrack { DEFAULT, CAMPFIRE, BOSS }

@export var default_music: AudioStream = preload("res://Resources/Sounds/Music/forest_music.mp3")
@export var campfire_music: AudioStream = preload("res://Resources/Sounds/Music/merchant_music.ogg")
@export var boss_music: AudioStream = preload("res://Resources/Sounds/Music/boss_music.mp3")

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_track: MusicTrack = -1 as MusicTrack
var _fade_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # So that music doesn't stop during dialogues
	
	# Create audio players dynamically
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	_player_a.bus = &"Music"
	_player_b.bus = &"Music"
	add_child(_player_a)
	add_child(_player_b)
	_active_player = _player_a

func save_player_state(health: int, currency: int) -> void:
	saved_health = health
	saved_currency = currency

func save_checkpoint(pos: Vector2, level_tag: String) -> void:
	current_checkpoint_pos = pos
	current_checkpoint_level = level_tag
	has_checkpoint = true

func get_enemy_kills(enemy_id: String) -> int:
	return enemy_kill_counts.get(enemy_id, 0)

func register_enemy_kill(enemy_id: String) -> void:
	if enemy_id == "":
		return
	enemy_kill_counts[enemy_id] = get_enemy_kills(enemy_id) + 1

func register_soul_destroyed(enemy_id: String, scene_path: String) -> void:
	destroyed_souls[enemy_id] = scene_path

func get_destroyed_soul_count() -> int:
	return destroyed_souls.size()

# One scene path per destroyed soul (duplicates when several souls were the same enemy type)
func get_destroyed_soul_scenes() -> Array:
	return destroyed_souls.values()

func has_item(item_id: String) -> bool:
	return item_id in owned_items

func add_item(item_id: String) -> void:
	if not has_item(item_id):
		owned_items.append(item_id)
		
func play_room_music(track: MusicTrack, fade_duration: float = 1.0) -> void:
	if _current_track == track:
		return # Do nothing if the requested track is already playing
	
	_current_track = track
	var stream := _get_stream_for_track(track)
	
	if stream == null:
		stop_music(fade_duration)
		return

	# Swap active players for crossfading
	var old_player := _active_player
	var new_player := _player_b if _active_player == _player_a else _player_a
	_active_player = new_player

	new_player.stream = stream
	new_player.volume_db = -80.0 # Start silent
	new_player.play()

	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	_fade_tween = create_tween().set_parallel(true)
	
	# Fade in new track
	_fade_tween.tween_property(new_player, "volume_db", 0.0, fade_duration)
	
	# Fade out old track
	if old_player.playing:
		_fade_tween.tween_property(old_player, "volume_db", -80.0, fade_duration)
		_fade_tween.chain().tween_callback(old_player.stop)

func stop_music(fade_duration: float = 1.0) -> void:
	_current_track = -1 as MusicTrack
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(_active_player, "volume_db", -80.0, fade_duration)
	_fade_tween.tween_callback(_active_player.stop)

func _get_stream_for_track(track: MusicTrack) -> AudioStream:
	match track:
		MusicTrack.DEFAULT: return default_music
		MusicTrack.CAMPFIRE: return campfire_music
		MusicTrack.BOSS: return boss_music
		_: return null
