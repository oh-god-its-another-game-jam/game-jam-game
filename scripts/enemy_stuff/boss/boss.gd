extends Node2D

var antigen_scene = preload("res://scenes/player/antigen.tscn")
var damage_number_scene = preload("res://scenes/ui/damage_num.tscn")
@onready var centre = $Centre

@onready var boss_character = $CharacterBody2D

# --- VARIABLES ---
const time_to_resize = 0.5

var rand : float
# import toxins
var toxin_speed = 750
var toxin_scene = preload("res://scenes/enemy_stuff/toxin.tscn")

# stats and meta
@onready var max_health = get_meta("max_health")
@onready var max_glucose = get_meta("max_glucose")
@onready var health = max_health
@onready var glucose = max_glucose
@onready var movement_speed = get_meta("movement_speed")
@onready var attack_range = get_meta("attack_range")
@onready var los_range = get_meta("los_range")

@onready var health_regen = get_meta("health_regen")
@onready var glucose_regen = get_meta("glucose_regen")
var movement_delta: float

# attack
var attack_timer: Timer
@onready var reload = get_meta("attack_reload")
@onready var attack_damage = get_meta("attack_damage")

# target the player
@onready var player_character = get_tree().get_first_node_in_group("Player")

var target_pos
var max_bullet_direction_rotation = 0.1

# state
enum State {idle, spotted, attack, dying}
var state := State.idle
#enum Target_type {player, cell}
@onready var target


# get navigation agent and raycast
@onready var nav: NavigationAgent2D = $CharacterBody2D/NavigationAgent2D
@onready var raycast: RayCast2D = $CharacterBody2D/LOS
var path_current
var path_next
var segment_dist
var idle_target_pos

@onready var sprite = $CharacterBody2D/Sprite2D
@onready var sprite_texture = sprite.texture
var diffuse_1 = preload("res://artwork/enemy_stuff/Virus1.png")
var normal_1 = preload("res://artwork/enemy_stuff/Virus1_n.png")
var diffuse_2 = preload("res://artwork/enemy_stuff/Virus2.png")
var normal_2 = preload("res://artwork/enemy_stuff/Virus2_n.png")
var diffuse_3 = preload("res://artwork/enemy_stuff/Virus3.png")
var normal_3 = preload("res://artwork/enemy_stuff/Virus3_n.png")
var texture_rand = randi_range(1,3)

# health bar
@onready var health_bar: ProgressBar = $CharacterBody2D/HealthBar

# Godot functions

func _ready() -> void:
	_change_health(health, max_health)

func _process(delta: float) -> void:
	if health_regen > 0:
		health = clamp(health + health_regen * delta, -max_health, max_health)
		_change_health(health, max_health)
	if glucose_regen > 0:
		glucose = clamp(glucose + glucose_regen * delta, -max_glucose, max_glucose)
	
func _physics_process(delta: float) -> void:
	pass

# --- USER FUNCTIONS ---
# Movement:
func _navigate_to_point_between(attack_target,compare) -> Vector2:
	# Nav path to the closest cell
	var path: PackedVector2Array = NavigationServer2D.map_get_path(
		nav.get_navigation_map(), 
		attack_target.global_position, 
		compare.global_position, 
		true
	)
	
	if path.size() > 1:
		# Find max point away where still in attack range
		var remaining_dist = attack_range
		for i in range(path.size() - 1, 0, -1):
			path_current = path[i]
			path_next = path[i-1]
			segment_dist = path_current.distance_to(path_next)
			
			if segment_dist >= remaining_dist:
				return path_current + (path_next - path_current).normalized() * remaining_dist
			else:
				# Have not yet reached the correct distance
				remaining_dist -= segment_dist
		# This code shouldn't ever run, but is needed to prevent error, and would be correct if it did run
		return path_next
	else:
		# No path found
		return attack_target.global_position + (boss_character.global_position - attack_target.global_position).normalized() * attack_range

func _move_to_position(move_pos:Vector2) -> void:
	nav.set_target_position(move_pos)

	if NavigationServer2D.map_get_iteration_id(nav.get_navigation_map()) == 0:
		boss_character.velocity = Vector2.ZERO
		return
	if nav.is_navigation_finished():
		boss_character.velocity = Vector2.ZERO
		return

	var next_path_position: Vector2 = nav.get_next_path_position()
	var target_direction: Vector2 = boss_character.global_position.direction_to(next_path_position)
	var preferred_velocity: Vector2 = target_direction * movement_speed

	if nav.avoidance_enabled:
		nav.set_velocity(preferred_velocity)
	else:
		boss_character.velocity.x = clamp(preferred_velocity.x,-movement_speed,movement_speed)
		boss_character.velocity.y = clamp(preferred_velocity.y,-movement_speed,movement_speed)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	boss_character.velocity = safe_velocity

	if target_pos:
		_move_to_position(target_pos)


# Health:
func _change_health(new: float, max_value: float):
	health_bar.max_value = max_value
	health_bar.value = new

# Attack:
func _check_attack() -> bool:
	if target == null:
		return false
	if boss_character.global_position.distance_to(target.global_position) > attack_range:
		return false
	if not get_meta("needs_los"):
		return true

	raycast.target_position = raycast.to_local(target.global_position)
	raycast.force_raycast_update()
	return raycast.is_colliding() and \
		(raycast.get_collider().is_in_group("Player") or \
		raycast.get_collider().is_in_group("cells"))

func _attack() -> void:
	var toxin = toxin_scene.instantiate()
	toxin.set_meta("attack_damage",attack_damage + randi_range(-attack_damage/5,attack_damage/5))
	get_parent().add_child(toxin)
	toxin.set_meta("shooter",get_instance_id())
	toxin.global_position = boss_character.global_position
	rand = randf_range(-max_bullet_direction_rotation,max_bullet_direction_rotation)
	toxin.velocity = (target.global_position - boss_character.global_position).normalized().rotated(rand)\
		 * toxin_speed


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
		
		_change_health(health,max_health)
	if health <= 0:
		Events.enemy_died_sound.emit()
		_die()

# Death:
func _die() -> void:
	state = State.dying

	var mat := $CharacterBody2D/Sprite2D.material as ShaderMaterial
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/progress", 1.0, 0.6)
	await tween.finished
	queue_free()

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
		"movement_speed": movement_speed,
		"attack_damage": attack_damage,
		"reload": reload,
		"enemy_size_divisor": Events.enemy_size_divisor,
		"texture_rand": texture_rand
	}

	return save_dict

func load_data(data: Dictionary) -> void:
	rotation = data["rotation"]
	scale = Vector2(data["scale_x"], data["scale_y"])
	boss_character.position = Vector2(data["body_x"], data["body_y"])
	health = data["health"]
	max_health = data["max_health"]
	glucose = data["glucose"]
	max_glucose = data["max_glucose"]
	movement_speed = data["movement_speed"]
	attack_damage = data["attack_damage"]
	reload = data["reload"]
	Events.enemy_size_divisor = data["enemy_size_divisor"]
	texture_rand = data["texture_rand"]

	attack_timer.wait_time = reload
	_change_health(health, max_health)
	
	if texture_rand == 1:
		sprite_texture.diffuse_texture = diffuse_1
		sprite_texture.normal_texture = normal_1
	elif texture_rand == 2:
		sprite_texture.diffuse_texture = diffuse_2
		sprite_texture.normal_texture = normal_2
	else:
		sprite_texture.diffuse_texture = diffuse_3
		sprite_texture.normal_texture = normal_3

# obligatory pf 🏳️‍🌈
