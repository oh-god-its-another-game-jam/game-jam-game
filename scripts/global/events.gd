extends Node

@onready var player = get_tree().get_first_node_in_group("Player")

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
signal soundtrack_request(sound: NodePath)
@warning_ignore_restore("unused_signal")

enum Levels {brain, heart, intestines, kidneys, liver, lungs, stomach, appendix, tutorial_lvl, other}
var level = Levels.appendix


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

var wait_time_timer: Timer

# Godot functions

func _ready() -> void:
	wait_time_timer = Timer.new()
	wait_time_timer.wait_time = 0.75
	wait_time_timer.one_shot = false
	add_child(wait_time_timer)
	wait_time_timer.timeout.connect(_cull_enemies.bind())
	wait_time_timer.start()
	
	_toggle_tutorial(false)

func _cull_enemies():
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		if player == null:
			return
	var closest = _get_closest_enemies(5)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null:
			return
		if enemy not in closest:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
		elif enemy in closest:
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
	

func _get_closest_enemies(num: int) -> Array[Node2D]:
	var enemy := get_tree().get_nodes_in_group("enemies")
	
	var origin: Vector2 = player.global_position
	enemy.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)

	var result: Array[Node2D] = []
	for i in mini(num, enemy.size()):
		result.append(enemy[i])
	return result


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
