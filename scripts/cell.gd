extends Node2D

@export var controlled_by = "enemy"

var damage_number_scene = preload("res://scenes/ui/damage_num.tscn")

# Variables for Enemy Replication
var enemy_max_health = 100.0
var enemy_max_glucose = 100.0
var enemy_glucose_regen = 0.0
var enemy_health_regen = 0.0
var enemy_movement_speed = 100.0
var enemy_attack_range = 400.0
var enemy_los_range = 800.0
var enemy_scale = 1.0
var enemy_attack_damage = 10.0
var enemy_attack_reload = 2.0

# Percentage chances for mutation
var max_health_mutation_chance =  5.0
var max_glucose_mutation_chance =  5.0
var glucose_regen_mutation_chance =  5.0
var health_regen_mutation_chance =  5.0
var movement_speed_mutation_chance =  5.0
var attack_range_mutation_chance =  5.0
var los_range_mutation_chance =  5.0
var attack_damage_mutation_chance =  5.0
var attack_reload_mutation_chance =  5.0

var rand

@onready var regen = get_meta("regen")

@onready var friendly_regen = get_meta("friendly_regen")
@onready var regen_range = get_meta("regen_range")
@onready var regen_emitter: GPUParticles2D = $RegenEmitter # maybe use CPU but idk..
@onready var enemy_regen_texture = preload("res://artwork/enemy_stuff/enemy_heal_particle.png")
@onready var player_regen_texture = preload("res://artwork/MainChara/player_heal_particle.png")

@onready var player = get_tree().get_first_node_in_group("Player")

var regen_particle_speed = 700
var base_particle_amount = 2.5
var particle_speed

enum State {no_regen,regen}
var state = State.no_regen

var time_until_regen = 10 
var timer_until_regen = time_until_regen

var virus_cell_attack_mult = 4

var recent_shooter : Node
var previous_collisions = []

@onready var max_health = get_meta("max_health",500)
@onready var health = max_health
@onready var light = $Sprite2D/PointLight2D
@onready var health_bar = $HealthBar

var spawn_timer
var spawn_time = 15 # How long it takes for enemies to spawn in seconds

@onready var sprite = $Sprite2D
@onready var sprite_texture = sprite.texture
var good_cell_asset = preload("res://artwork/Cell/CellGood.png")
var bad_cell_asset = preload("res://artwork/Cell/CellBad.png")

signal captured_by_player

# Godot functions:
func _ready() -> void:
	if sprite_texture:
		sprite.texture = sprite_texture.duplicate()
		sprite_texture = sprite.texture
	_create_spawn_timer()
	
	regen_emitter.amount = round(base_particle_amount * (Events.effects_scale/100))
	
	if controlled_by == "player":
		light.color = "1CEE24"
		regen_emitter.texture = player_regen_texture
		sprite_texture.diffuse_texture = good_cell_asset
	else:
		light.color = "EE1C24"
		regen_emitter.texture = enemy_regen_texture
		sprite_texture.diffuse_texture = bad_cell_asset
	
	_change_health(health,max_health)

func _process(delta: float) -> void:
	timer_until_regen += delta
	
	if state == State.regen:
		health += regen * delta
		_change_health(health,max_health)
	
	if health <= 0:
		_capture()
	
	if light.color == Color("ee1c24") && controlled_by == "player":
		_player_capture()
	elif light.color == Color("1cee24") && controlled_by == "enemy":
		_virus_capture()
	
	if health == max_health:
		state = State.no_regen
	elif timer_until_regen >= time_until_regen:
		state = State.regen
		
	_regen_entites(controlled_by, delta)
	
	if get_tree().current_scene.scene_file_path == "res://scenes/levels/tutorial.tscn":
		spawn_timer.paused = true

# User functions:
# Enemy Spawning:
func _create_spawn_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_time
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_mutate_chance.bind())
	add_child(spawn_timer)
	if controlled_by == "player":
		spawn_timer.paused = true
	else:
		spawn_timer.paused = false

func _mutate_chance() -> void:
	if randf() * 100 < attack_damage_mutation_chance:
		print("Attack Damage Mutation in ", self , " in organ ", get_parent().name)
		rand = randf_range(0.9,1.2)
		enemy_attack_damage *= rand
		enemy_scale *= rand
	if randf() * 100 < attack_range_mutation_chance:
		print("Attack Range Mutation in ",self, " in organ ", get_parent().name)
		rand = randf_range(0.9,1.2)
		enemy_attack_range *= rand
		enemy_scale *= rand
	if randf() * 100 < attack_reload_mutation_chance:
		print("Attack Reload Mutation in ",self, " in organ ", get_parent().name)
		rand = randf_range(0.9,1.2)
		enemy_attack_reload *= rand
		enemy_scale *= rand
	if randf() * 100 < los_range_mutation_chance:
		print("LOS Range Mutation in ",self, " in organ ", get_parent().name)
		rand = randf_range(0.9,1.2)
		enemy_los_range *= rand
		enemy_scale *= rand
	if randf() * 100 < health_regen_mutation_chance:
		print("Enemy Health Regen Mutation in ",self, " in organ ", get_parent().name)
		if enemy_health_regen != 0:
			rand = randf_range(0.9,1.2)
			enemy_health_regen *= rand
			enemy_scale *= rand
		else:
			rand = randf_range(0,1)
			enemy_health_regen = rand
			enemy_scale *= (1+rand)
	if randf() * 100 < max_health_mutation_chance:
		print("Max Health Mutation in ",self, " in organ ", get_parent().name)
		rand = randf_range(0.9,1.2)
		enemy_max_health *= rand
		enemy_scale *= rand
	if randf() * 100 < max_glucose_mutation_chance:
		print("Max Glucose Mutation in ",self, " in organ ", get_parent().name)
		rand = randf_range(0.9,1.2)
		enemy_max_glucose *= rand
		enemy_scale *= rand
	if randf() * 100 < glucose_regen_mutation_chance:
		print("Glucose Regen Mutation in ",self, " in organ ", get_parent().name)
		if enemy_glucose_regen != 0:
			rand = randf_range(0.9,1.2)
			enemy_glucose_regen *= rand
			enemy_scale *= rand
		else:
			rand = randf_range(0,1)
			enemy_glucose_regen = rand
			enemy_scale *= (1+rand)
	if randf() * 100 < movement_speed_mutation_chance:
		print("Movement Speed Mutation in ",self, " in organ ", get_parent().name)
		rand = randf_range(0.9,1.2)
		enemy_movement_speed *= rand
		enemy_scale *= rand
	_create_enemy()

func _create_enemy() -> void:
	var node = load("res://scenes/enemy_stuff/basic_enemy.tscn").instantiate()
	
	node.set_meta("attack_damage",enemy_attack_damage)
	node.set_meta("attack_range",enemy_attack_range)
	node.set_meta("glucose_regen",enemy_glucose_regen)
	node.set_meta("health_regen",enemy_health_regen)
	node.set_meta("movement_speed",enemy_movement_speed)
	node.set_meta("attack_range",enemy_attack_range)
	node.set_meta("los_range",enemy_los_range)
	node.set_meta("scale",enemy_scale)
	node.set_meta("max_health",enemy_max_health)
	node.set_meta("max_glucose",enemy_max_glucose)
	
	node.global_position = global_position + Vector2(80,0)
	get_parent().add_child(node)

# Capture:
func _capture() -> void:
	health = 0.1
		
	if controlled_by == "player":
		_virus_capture()
	elif controlled_by == "enemy":
		_player_capture()

func _virus_capture() -> void:
	controlled_by = "enemy"
	regen_emitter.texture = enemy_regen_texture
	sprite_texture.diffuse_texture = bad_cell_asset
	light.color = "EE1C24"
	
	state = State.regen
	timer_until_regen = time_until_regen
	
	if get_tree().current_scene.scene_file_path != "res://scenes/levels/tutorial.tscn":
		spawn_timer.paused = false
	
	# Set variables for duplication

func _player_capture() -> void:
	captured_by_player.emit()
	
	controlled_by = "player"
	regen_emitter.texture = player_regen_texture
	sprite_texture.diffuse_texture = good_cell_asset
	light.color = "1CEE24"
	
	state = State.regen
	timer_until_regen = time_until_regen
	
	spawn_timer.paused = true

# Health:
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Antigens") and is_inside_tree():
		if controlled_by == "enemy":
			if state == State.regen:
				timer_until_regen = 0
				state = State.no_regen
			_take_damage(body.get_meta("attack_damage"), Color(0.0, 0.73, 0.167, 1.0))
		elif controlled_by == "player":
			health = clamp(health + body.get_meta("attack_damage"),0,max_health)
		
		body.queue_free()
		
	if body.is_in_group("Toxins") and controlled_by == "player" and is_inside_tree():
		if state == State.regen:
			timer_until_regen = 0
			state = State.no_regen
			
		_take_damage(body.get_meta("attack_damage") * virus_cell_attack_mult)
		
		if body.get_meta("shooter") != null:
			var shooter_id = body.get_meta("shooter")
			var shooter_node = instance_from_id(shooter_id)
			
			if is_instance_valid(shooter_node):
				recent_shooter = shooter_node
		body.queue_free()
		
	_change_health(health,max_health)

func _take_damage(amount: float, color: Color = Color(0.987, 0.215, 0.0, 1.0)) -> void:
	health -= amount
	
	var num := damage_number_scene.instantiate()
	get_tree().current_scene.add_child(num)
	num.global_position = global_position + Vector2(0, -20)
	num.setup(amount, color)

func _change_health(new: float, max_value: float):
	health_bar.max_value = max_value
	health_bar.value = new

func _regen_entites(_controlled_by, delta) -> void:
	var target: Node2D = null
	if _controlled_by == "player":
		target = player
	else:
		target = _get_closest_enemy()
	
	if target != null and global_position.distance_to(target.global_position) < regen_range:
		regen_emitter.look_at(target.global_position)
		particle_speed = global_position.distance_to(target.global_position) * 2 / regen_emitter.lifetime 
		
		var mat = regen_emitter.process_material as ParticleProcessMaterial
		if mat:
			mat.set_param_min(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, particle_speed)
			mat.set_param_max(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, particle_speed)
		regen_emitter.emitting = true
		
		if controlled_by == "enemy":
			target.get_parent()._ext_heal(friendly_regen,delta)
		else:
			target._ext_heal(friendly_regen,delta)
		
	else:
		regen_emitter.emitting = false

func _get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < closest_dist:
			closest_dist = distance
			closest = enemy

	return closest

# Save / Load:
func save() -> Dictionary:
	var save_dict = {
		"filename": get_scene_file_path(),
		"parent": get_tree().current_scene.get_path_to(get_parent()),
		"pos_x": position.x,
		"pos_y": position.y,
		"rotation": rotation,
		"scale_x": scale.x,
		"scale_y": scale.y,
		"controlled_by": controlled_by,
		"health": health,
		"max_health": max_health,
		"state": state,
		"timer_until_regen": timer_until_regen,
		
		"enemy_attack_damage": enemy_attack_damage,
		"enemy_attack_range": enemy_attack_range,
		"enemy_attack_reload": enemy_attack_reload,
		"enemy_glucose_regen": enemy_glucose_regen,
		"enemy_health_regen": enemy_health_regen,
		"enemy_los_range": enemy_los_range,
		"enemy_max_glucose": enemy_max_glucose,
		"enemy_max_health": enemy_max_health,
		"enemy_movement_speed": enemy_movement_speed,
		"enemy_scale": enemy_scale,
		"light_colour": light.color.to_html()
	}

	return save_dict

func load_data(data: Dictionary) -> void:
	rotation = data["rotation"]
	scale = Vector2(data["scale_x"], data["scale_y"])
	controlled_by = data["controlled_by"]
	max_health = data["max_health"]
	health = data["health"]
	state = (data["state"])
	timer_until_regen = data["timer_until_regen"]
	light.color = Color.html(data["light_colour"])
	
	
	enemy_attack_damage = data["enemy_attack_damage"]
	enemy_attack_range = data["enemy_attack_range"]
	enemy_attack_reload = data["enemy_attack_reload"]
	enemy_glucose_regen = data["enemy_glucose_regen"]
	enemy_health_regen = data["enemy_health_regen"]
	enemy_los_range = data["enemy_los_range"]
	enemy_max_glucose = data["enemy_max_glucose"]
	enemy_max_health = data["enemy_max_health"]
	enemy_movement_speed = data["enemy_movement_speed"]
	enemy_scale = data["enemy_scale"]

	if controlled_by == "player":
		light.color = "1CEE24"
		regen_emitter.texture = player_regen_texture
		sprite_texture.diffuse_texture = good_cell_asset
		
	else:
		light.color = "EE1C24"
		regen_emitter.texture = enemy_regen_texture
		sprite_texture.diffuse_texture = bad_cell_asset

	_change_health(health, max_health)


# obligatory pf 🏳️‍🌈
