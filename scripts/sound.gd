extends Node2D

@onready var player_SFX: AudioStreamPlayer = $player_SFX
@onready var enemy_SFX: AudioStreamPlayer = $enemy_SFX

@onready var character = get_tree().get_first_node_in_group("Player")

# player_SFX:
var error_sound = preload("res://sounds/win_xp_error.mp3")

# enemy_SFX
var enemy_die_sound = preload("res://sounds/enemy_dying.mp3")

func play_sound(player: AudioStreamPlayer, sound: AudioStream) -> void:
	player.stop()
	player.stream = sound
	player.play()

func _ready() -> void:
	Events.error_sound.connect(play_sound.bind(player_SFX, error_sound))
	Events.enemy_died.connect(play_sound.bind(enemy_SFX, enemy_die_sound))
