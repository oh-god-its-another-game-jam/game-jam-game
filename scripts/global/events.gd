extends Node

@warning_ignore_start("unused_signal")
signal enemy_died_sound
signal error_sound
signal dash_sound
signal player_take_damage
signal player_shoot
signal minimap_toggle
signal notify_send
signal enemy_resized
signal boss_health_changed
signal screen_ripple(origin: Vector2)
@warning_ignore_restore("unused_signal")

var enemy_size_divisor: float = 2.0
var enemy_max_scale: float = 1 # 2x starting size
var enemy_min_scale: float = 0.5 # 1/2x starting size

var effects_scale: float = 100.0

var master_volume: float = 100.0
var music_volume: float = 100.0
var sfx_volume: float = 100.0

var meme_SFX: bool = false

var tutorial = false
var allowed_actions: Dictionary

# Godot functions

func _ready() -> void:
	_toggle_tutorial(false)

# User functions

func _toggle_tutorial(value) -> void:
	if not value:
		tutorial = false
		allowed_actions = {
			"move" = true,
			"toggle_minimap" = true,
			"dash" = true,
			"shoot" = true,
			"parry" = false
		}
	else:
		tutorial = true
		allowed_actions = {
			"move" = false,
			"toggle_minimap" = false,
			"dash" = false,
			"shoot" = false,
			"parry" = false
		}

func _change_effects_scale(new: float) -> void:
	effects_scale = new

func _change_master_volume(new: float) -> void:
	master_volume = new

func _change_music_volume(new: float) -> void:
	music_volume = new

func _change_sfx_volume(new: float) -> void:
	sfx_volume = new
	
func _enemy_scale_too_large(enemy_scale: float) -> void:
	enemy_size_divisor *= enemy_scale / enemy_max_scale
	print(enemy_size_divisor)

# obligatory pf 🏳️‍🌈
