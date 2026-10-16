extends Sprite2D

var antigen_scene = preload("res://scenes/antigen.tscn")

@onready var antigen_spawner = $AntigenSpawner
@onready var health_bar = get_tree().get_first_node_in_group("PlayerHealthBar")

var health_bar_inter_frame_time = 0.1

# --- PLAYER STATS ---

var max_health: float = 100.0
var health: float = 100.0
var max_glucose: float = 100.0
var glucose: float = 100.0
var glucose_regen: float = 5.0
var attack_damage = 50.0

var ammo: int = 10

signal health_changed(new_health: float, max_health: float)
signal glucose_changed(new_glucose: float, max_glucose: float)

# --- MOVEMENT ---
var velocity = Vector2(0,0)
var max_speed : float = 800
var time_to_max_speed : float = 0.2
var current_speed : float = 0
var angle_deg = 0 # store angle at start

# --- DASHING ---

var dash_tween: Tween
var is_dashing: bool = false
var dash_speed: float = 2000.0
var dash_duration: float = 0.15
var dash_direction: Vector2 = Vector2.ZERO
var dashing: bool = false
var base_scale: Vector2
var dash_glucose_use: float = 20.0


func _ready() -> void:	
	base_scale = scale
	
	glucose_changed.emit.call_deferred(glucose, max_glucose)
	health_changed.emit.call_deferred(health, max_health)

func shoot_antigen():
	if ammo == 0: # @GoldenFootie should we do glucose for this?
		Events.error_sound.emit()
		return
	ammo -= 1
	
	var antigen = antigen_scene.instantiate()
	owner.add_child(antigen)
	antigen.global_transform = antigen_spawner.global_transform
	antigen.set_meta("attack_damage",attack_damage)

func dash():
	if dashing:
		return
	elif glucose < dash_glucose_use:
		Events.error_sound.emit()
		return
	
	glucose -= dash_glucose_use
	
	dashing = true
	dash_direction = (get_global_mouse_position() - global_position).normalized()

	if dash_tween:
		dash_tween.kill()
	scale = base_scale

	dash_tween = create_tween()
	dash_tween.tween_property(self, "scale", base_scale * Vector2(0.5, 1.6), 0.04)
	dash_tween.tween_interval(dash_duration - 0.04)
	dash_tween.tween_property(self, "scale", base_scale, 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	health_bar.material = load("res://palette_swap_resources/1_invuln_health_bar_light.tres")
	await get_tree().create_timer(dash_duration/4).timeout
	health_bar.material = load("res://palette_swap_resources/2_invuln_health_bar_full.tres")
	await get_tree().create_timer(dash_duration/2).timeout
	health_bar.material = load("res://palette_swap_resources/3_invuln_health_bar_dark.tres")
	await get_tree().create_timer(dash_duration/4).timeout
	health_bar.material = load("res://palette_swap_resources/0_health_bar.tres")
	dashing = false

func _physics_process(delta: float) -> void:
	if health <= 0:
		_game_over()
	# --- SHOOTING ---
	if not dashing:
		# Makes the player look at the mouse
		look_at(get_global_mouse_position()) 
		rotation_degrees += 90
	
	if Input.is_action_just_pressed("left_click"):
		shoot_antigen()
	
	# --- DASHING ---
	
	if Input.is_action_just_pressed("right_click"):
		dash()	
	
	if dashing:
		position += dash_direction * dash_speed * delta
		return
	
	# --- MOVEMENT ---
	var moving = true

	# hopefully self explanatory
	if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_right"):
		angle_deg = 45
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed) # Calculates speed with acceleration
	elif Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_left"):
		angle_deg = 315
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed)
	elif Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_right"):
		angle_deg = 135
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed)
	elif Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_left"):
		angle_deg = 225
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed)
	elif Input.is_action_pressed("ui_up"):
		angle_deg = 0
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed)
	elif Input.is_action_pressed("ui_right"):
		angle_deg = 90
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed)
	elif Input.is_action_pressed("ui_down"):
		angle_deg = 180
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed)
	elif Input.is_action_pressed("ui_left"):
		angle_deg = 270
		current_speed = clamp(current_speed + (delta/time_to_max_speed) * max_speed,0,max_speed)
	else:
		moving = false
		current_speed = 0
	
	if moving:
		velocity = Vector2.UP.rotated(deg_to_rad(angle_deg)) * current_speed
		position += velocity * delta

func _process(delta: float) -> void:
	var old_glucose := glucose
	var old_health := health
	
	glucose = min(glucose + glucose_regen * delta, max_glucose)
	
	if glucose != old_glucose:
		glucose_changed.emit(glucose, max_glucose)
	if health != old_health:
		health_changed.emit(health, max_health)

func _game_over() -> void:
	# Display end screen, this is temporary
	get_tree().quit()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not dashing:
		if body.is_in_group("Toxins"):
			print("Player hit")
			health -= body.get_meta("attack_damage",0)
			body.queue_free()
			_animate_health_bar()

func _animate_health_bar() -> void:
	# Animation (please forgive me for my sins, I can't find a better way to do this):
	health_bar.material = load("res://palette_swap_resources/1_health_bar_inside_white.tres")
	await get_tree().create_timer(health_bar_inter_frame_time).timeout
	health_bar.material = load("res://palette_swap_resources/2_health_bar_white.tres")
	health_changed.emit.call_deferred(health, max_health)
	await get_tree().create_timer(health_bar_inter_frame_time).timeout
	health_bar.material = load("res://palette_swap_resources/3_health_bar_outside_white.tres")
	await get_tree().create_timer(health_bar_inter_frame_time).timeout
	health_bar.material = load("res://palette_swap_resources/0_health_bar.tres")
	
# obligatory pf 🏳️‍🌈
