extends Node2D

# --- VARIABLES ---

var rand : float

# import toxins
var toxin_scene = preload("res://scenes/enemy_stuff/toxin.tscn")
@onready var toxin_spawner = $Sprite2D/ToxinSpawner
@onready var attack_damage = get_meta("attack_damage")

# stats and meta
@onready var max_health = get_meta("max_health")
@onready var max_glucose = get_meta("max_glucose")
@onready var health = max_health
@onready var glucose = max_glucose
@onready var movement_speed = get_meta("movement_speed")
var movement_delta: float

# attack
var attack_timer: Timer
@onready var reload = 2.0
@onready var attack_damage = get_meta("attack_damage")


# state
enum State {idle, spotted, attack}
var state := State.idle

# target the player
@onready var target = get_tree().get_first_node_in_group("Player")

# get navigation agent and raycast
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var raycast: RayCast2D = $LOS

# cloning
var probability_health_change = 100

# health bar
@onready var health_bar: ProgressBar = $HealthBar

# Godot functions

func _ready() -> void:
	attack_timer = Timer.new()
	attack_timer.wait_time = reload
	attack_timer.autostart = true
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_attack.bind())
	add_child(attack_timer)
	
	nav.velocity_computed.connect(Callable(_on_velocity_computed))
	_change_health(health, max_health)

func _physics_process(delta: float) -> void:
	state = _check_state()
	if state == State.spotted:
		_spotted(delta)
	if state == State.attack:
		attack_timer.paused = false
	else:
		attack_timer.paused = true
	
	if state != State.idle:
		look_at(target.global_position) 

# --- USER FUNCTIONS ---

func _change_health(new: float, max_value: float):
	health_bar.max_value = max_value
	health_bar.value = new

func _check_state() -> State:
	if _check_attack():
		return State.attack
	elif _check_los():
		return State.spotted
	else:
		return State.idle

# then we can just derive behavoiur from here, ie. state idle has its own distinct behavoiur from attack...

# attack

func _check_attack() -> bool:
	if global_position.distance_to(target.global_position) > get_meta("attack_range"):
		return false
	if not get_meta("needs_los"):
		return true

	raycast.target_position = raycast.to_local(target.global_position)
	raycast.force_raycast_update()
	return raycast.is_colliding() and raycast.get_collider().is_in_group("Player")

func _attack() -> void:
	var toxin = toxin_scene.instantiate()
	owner.add_child(toxin)
	toxin.global_transform = toxin_spawner.global_transform
	toxin.set_meta("attack_damage",attack_damage)

func _check_los() -> bool:
	if global_position.distance_to(target.global_position) > get_meta("los_range"):
		return false

	if not get_meta("needs_los"):
		return true

	raycast.target_position = raycast.to_local(target.global_position)
	raycast.force_raycast_update()
	return raycast.is_colliding() and raycast.get_collider().is_in_group("Player")

func _chase(delta) -> void:
	#print("chasing")
	movement_delta = movement_speed * delta
	nav.set_target_position(target.global_position)
	#print(target)

	if NavigationServer2D.map_get_iteration_id(nav.get_navigation_map()) == 0:
		#print(NavigationServer2D.map_get_iteration_id(nav.get_navigation_map()))
		return
	if nav.is_navigation_finished():
		#print(nav.is_navigation_finished())
		return
	
	var next_path_position: Vector2 = nav.get_next_path_position()
	#print(nav.get_next_path_position())
	#var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_delta

	nav.set_velocity(global_position.direction_to(next_path_position) * movement_speed)
	var direction: Vector2 = global_position.direction_to(next_path_position)
	global_position += direction * movement_delta

func _spotted(delta) -> void:
	#print("player spotted")
	_chase(delta)
	# sound effects, animations etc..

# i don't actually think this is necessary
func _on_velocity_computed(safe_velocity: Vector2) -> void: #https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
	global_position += safe_velocity * get_physics_process_delta_time()

func _duplicate_self() -> void:
	# Make an animation, add that here
	
	var new_enemy = duplicate()
	if randf() * 100 <= probability_health_change:
		rand = randf_range(0.9,1.2)
		new_enemy.set_meta("max_health",get_meta("max_health")*rand)
		new_enemy.set_meta("scale",new_enemy.get_meta("scale")*rand)
		new_enemy.scale *= rand
	get_parent().call_deferred("add_child",new_enemy)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Antigens"):
		health -= body.get_meta("attack_damage")
		_change_health(health,max_health)
		body.queue_free()
	if health <= 0:
		Events.enemy_died.emit()
		queue_free()


# obligatory pf 🏳️‍🌈
