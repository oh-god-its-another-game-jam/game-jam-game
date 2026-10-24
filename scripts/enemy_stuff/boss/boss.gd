extends Node2D

var antigen_scene = preload("res://scenes/player/antigen.tscn")
var damage_number_scene = preload("res://scenes/ui/damage_num.tscn")
var basic_enemy_scene = preload("res://scenes/enemy_stuff/basic_enemy.tscn")
@onready var mouth = $CharacterBody2D/Mouth

@onready var boss_character = $CharacterBody2D

@onready var hitbox = $CharacterBody2D/Hitbox

var heart_activated: bool = false
var done: bool = false

# --- VARIABLES ---
var rand: float
# import toxins
var toxin_speed = 750
var toxin_scene = preload("res://scenes/enemy_stuff/toxin.tscn")

# stats and meta
@onready var max_health = 2000
@onready var max_glucose = get_meta("max_glucose")
@onready var health = 2000
@onready var glucose = max_glucose


# attack
#var attack_switch_timer: Timer
#@onready var switch_time = get_meta("attack_switch_time")
@onready var stream_attack_damage = get_meta("stream_attack_damage")
@onready var spin_attack_damage = get_meta("spin_attack_damage")

# target the player
@onready var player_character: Node2D = _get_player()

func _get_player() -> Node2D:
	if not is_instance_valid(player_character) or player_character.is_queued_for_deletion():
		player_character = get_tree().get_first_node_in_group("Player")
		if player_character and player_character.is_queued_for_deletion():
			player_character = null
	return player_character

@onready var vec_to_player: Vector2

var target_pos
var max_bullet_direction_rotation = 0.1

# state
enum Stage {stage1, stage2, stage3}
var stage = Stage.stage1

enum State {attack, dying}
var state := State.attack

enum Attack {spawn_enemies, spin_attack, ground_shake, toxin_stream}
var curr_attack = Attack.spawn_enemies
var allowed_attacks: Array = [Attack.spawn_enemies, Attack.spin_attack] #var allowed_attacks: Array = [Attack.spawn_enemies, Attack.spin_attack, Attack.ground_shake, Attack.toxin_stream]

var attk_in_progress := false

# Godot functions

func _ready() -> void:
	pass

	
func _physics_process(_delta: float) -> void:
	player_character = _get_player()
	if player_character == null:
		return
	
	_check_stage()
	vec_to_player = player_character.global_position - global_position
	if heart_activated and not done:
		done = true
		attk_in_progress = false
		Events.soundtrack_request.emit("res://sounds/Tenebre_Rosso_Sangue.mp3")
	elif not heart_activated:
		attk_in_progress = true
	
	if not attk_in_progress:
		_attack_switch()
		if curr_attack == Attack.spawn_enemies:
			_attack_spawn_enemies()
		elif curr_attack == Attack.spin_attack:
			_attack_spin()
		elif curr_attack == Attack.ground_shake:
			_attack_ground_shake()
		elif curr_attack == Attack.toxin_stream:
			_attack_toxin_stream()


# --- USER FUNCTIONS ---

func _check_stage() -> void:
	if float(health)/float(max_health) < 0.5 and stage == Stage.stage1:
		health *= 1.5
		_change_health(health, max_health)
		allowed_attacks.append(Attack.toxin_stream)
		stage = Stage.stage2
	elif health/max_health < 0.3 and stage == Stage.stage2:
		health *= 1.25
		_change_health(health, max_health)
		allowed_attacks.append(Attack.ground_shake)
		stage = Stage.stage3

func _attack_spawn_enemies() -> void:
	attk_in_progress = true
	for x in range(5):
		await get_tree().create_timer(2.0).timeout
		var enemy = basic_enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = mouth.global_position
		enemy.shot_by_boss = true
		enemy.boss_set_vec = vec_to_player.normalized()
		enemy.boss_set_speed = 200
	attk_in_progress = false

func _attack_spin() -> void:
	attk_in_progress = true
	var ang := 0.0
	var intervals: int = 36
	for x in range(intervals):
		await get_tree().create_timer(0.1).timeout
		var toxin = toxin_scene.instantiate()
		toxin.set_meta("attack_damage",spin_attack_damage + randi_range(-spin_attack_damage/5,spin_attack_damage/5))
		get_parent().add_child(toxin)
		toxin.set_meta("shooter",get_instance_id())
		toxin.global_position = boss_character.global_position
		rand = randf_range(-max_bullet_direction_rotation,max_bullet_direction_rotation)
		toxin.velocity = Vector2.RIGHT.rotated(ang) * toxin_speed
		ang += 360.0/intervals
	attk_in_progress = false

func _attack_ground_shake() -> void:
	attk_in_progress = true
	for x in range(3):
		await get_tree().create_timer(1).timeout
		Events.screen_ripple.emit(get_viewport().get_canvas_transform() * global_position)
		#if player_character.global_position.distance_to(global_position) < 500:
			#player_character.ext_heal(-50)
	attk_in_progress = false

func _attack_toxin_stream() -> void:
	attk_in_progress = true
	var bullets: int = 50
	for x in range(bullets):
		await get_tree().create_timer(5.0/bullets).timeout
		var toxin = toxin_scene.instantiate()
		toxin.set_meta("attack_damage",stream_attack_damage + randi_range(-stream_attack_damage/5,stream_attack_damage/5))
		get_parent().add_child(toxin)
		toxin.set_meta("shooter",get_instance_id())
		toxin.global_position = boss_character.global_position
		rand = randf_range(-max_bullet_direction_rotation,max_bullet_direction_rotation)
		toxin.velocity = (vec_to_player + Vector2.RIGHT.rotated(randf_range(-10,10))) * toxin_speed
	attk_in_progress = false

# Health:
func _change_health(new: float, max_value: float):
	Events.boss_health_changed.emit(new, max_value, true)


func _attack_switch() -> void:
	curr_attack = allowed_attacks.pick_random()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if state == State.dying:
		return
	if body.is_in_group("Antigens"):
		var amount = body.get_meta("attack_damage")
		health -= amount
		
		var num := damage_number_scene.instantiate()
		get_tree().current_scene.add_child(num)
		num.global_position = boss_character.global_position + Vector2(0, -20)
		num.setup(amount)
		
		body.queue_free()
		
		_change_health(health,max_health)
	if health <= 0:
		_die()

func _die() -> void:
	print("died")
	queue_free()
	get_tree().change_scene_to_file("res://scenes/victory.tscn")

func save() -> Dictionary:
	var save_dict = {
		"filename": get_scene_file_path(),
		"parent": get_tree().current_scene.get_path_to(get_parent()),
		"pos_x": position.x,
		"pos_y": position.y,
		"rotation": rotation,
		"scale_x": scale.x,
		"scale_y": scale.y,
		"body_x": boss_character.position.x,
		"body_y": boss_character.position.y,
		"health": health,
		"max_health": max_health,
		"glucose": glucose,
		"max_glucose": max_glucose,
		"stream_attack_damage": stream_attack_damage,
		"spin_attack_damage": spin_attack_damage,
		"allowed_attacks": allowed_attacks,
		"stage": stage,
		"state": state,
	}

	return save_dict

func load_data(data: Dictionary) -> void:
	position = Vector2(data["pos_x"], data["pos_y"])
	rotation = data["rotation"]
	scale = Vector2(data["scale_x"], data["scale_y"])
	boss_character.position = Vector2(data["body_x"], data["body_y"])
	health = data["health"]
	max_health = data["max_health"]
	glucose = data["glucose"]
	max_glucose = data["max_glucose"]
	stream_attack_damage = data["stream_attack_damage"]
	spin_attack_damage = data["spin_attack_damage"]

	allowed_attacks = []
	for a in data["allowed_attacks"]:
		allowed_attacks.append(int(a))
	stage = int(data["stage"]) as Stage
	state = int(data["state"]) as State

	attk_in_progress = false
	_change_health(health, max_health)
	_change_health(health, max_health)

# obligatory pf 🏳️‍🌈
