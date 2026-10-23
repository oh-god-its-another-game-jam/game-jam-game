extends Node2D

# player_SFX:
var error_sound = preload("res://sounds/win_xp_error.mp3")
var dash_sound = preload("res://sounds/dash_sound.mp3")
var take_damage_sound = preload("res://sounds/take_damage_player.mp3")
var take_damage_meme_sound = preload("res://sounds/take_damage_player_meme.mp3")

# enemy_SFX
var enemy_die_sound = preload("res://sounds/enemy_dying.mp3")

# music
var garbage_wastes = preload("res://sounds/Garbage_Worms.mp3")

@onready var player_SFX: AudioStreamPlayer = $player_SFX
@onready var enemy_SFX: AudioStreamPlayer = $enemy_SFX
@onready var music1: AudioStreamPlayer = $music1
@onready var music2: AudioStreamPlayer = $music2

var timing := {
	"res://sounds/Garbage_Worms.mp3": 160,
	"res://sounds/Tenebre_Rosso_Sangue.mp3": 176
}


signal beat(num: int)
var beat_position := 0.0
var last_beat := -1
# Godot functions

func _ready() -> void:
	Events.error_sound.connect(play_sound.bind(player_SFX, error_sound))
	Events.enemy_died_sound.connect(play_sound.bind(enemy_SFX, enemy_die_sound))
	Events.dash_sound.connect(play_sound.bind(player_SFX, dash_sound))
	Events.player_take_damage.connect(play_sound.bind(player_SFX, take_damage_sound, take_damage_meme_sound))
	Events.soundtrack_request.connect(s_req)
	switch_track(music1, music2, garbage_wastes)
	print("music: ", Events.music_volume, " sfx: ", Events.sfx_volume, " master: ", Events.master_volume)

func _process(_delta: float) -> void:
	var vol := _get_music_volume()
	if not is_equal_approx(music1.volume_linear, vol):
		music1.volume_linear = vol
		music2.volume_linear = vol
	
	if not music2.playing:
		return
	var bpm: float = timing.get(music2.stream.resource_path, 120)
	var t := music2.get_playback_position() \
		+ AudioServer.get_time_since_last_mix() \
		- AudioServer.get_output_latency()
	beat_position = t * bpm / 60.0
	var beat_no := floori(beat_position)
	if beat_no != last_beat:
		last_beat = beat_no
		beat.emit(beat_no)
# User functions

func _get_music_volume() -> float:
	return clampf((Events.music_volume / 100.0) * (Events.master_volume / 100.0), 0.0, 1.0)

func s_req(sound:NodePath):
	var sound_obj = load(sound)
	switch_track(music1, music2, sound_obj)


func play_sound(player: AudioStreamPlayer, sound: AudioStream, meme_SFX = null) -> void:
	player.stop()
	if Events.meme_SFX and meme_SFX != null:
		player.stream = meme_SFX
	else:
		player.volume_linear = clampf((Events.sfx_volume / 100.0) * (Events.master_volume / 100.0), 0.0, 1.0)
		player.stream = sound
	player.play()

func switch_track(player1: AudioStreamPlayer, player2: AudioStreamPlayer, sound: AudioStream, fade_time: float = 0.0) -> void:
	if fade_time <= 0.0:
		player1.stop()
		player2.stream = sound
		player2.volume_db = 0.0
		player2.play()
		return

	var tween_out := create_tween()
	tween_out.tween_property(player1, "volume_db", -80.0, fade_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_out.tween_callback(player1.stop)

	await get_tree().create_timer(fade_time / 2.0).timeout

	player2.stream = sound
	player2.volume_db = -80.0
	player2.play()

	var tween_in := create_tween()
	tween_in.tween_property(player2, "volume_db", 0.0, fade_time / 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# obligatory pf 🏳️‍🌈
