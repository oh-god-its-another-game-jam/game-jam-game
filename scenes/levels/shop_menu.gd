extends CanvasLayer

signal shop_exited

var button_index: int = 0
var buttons: Array
@onready var button_indicator = $SelectedButtonIndicator
@onready var player = get_tree().get_first_node_in_group("Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	_find_buttons()
	_check_upgrades()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not is_instance_valid("Player"):
		player = get_tree().get_first_node_in_group("Player")
	if visible:
		_check_upgrades()
		get_tree().paused = true
		if Input.is_action_just_pressed("ui_down") or \
			Input.is_action_just_pressed("ui_right"):
			# Move button selector down
			button_index += 1
			
			if button_index > len(buttons) - 1:
				button_index -= len(buttons)
			
			button_indicator.position.y = buttons[button_index].global_position.y
		if Input.is_action_just_pressed("ui_up") or \
			Input.is_action_just_pressed("ui_left"):
			# Move button selector up
			button_index -= 1
			
			if button_index < 0:
				button_index += len(buttons)
			
			button_indicator.position.y = buttons[button_index].global_position.y
		
		if Input.is_action_just_pressed("escape"):
			_return()
			
		if Input.is_action_just_pressed("ui_accept"):
			call(buttons[button_index].name)

func _find_buttons():
	buttons = []
	for child in $Buttons.get_children(false):
		if child.is_in_group("Buttons"):
			buttons.append(child)
			
func _check_upgrades():
	if Upgrades.attack_upgrades["triple_antigens"] == true and get_node_or_null("Buttons/_triple_antigens") != null:
		$Buttons/_triple_antigens.queue_free()
	_find_buttons()

func _return():
	get_tree().paused = false
	visible = false
	shop_exited.emit()

func _triple_antigens() -> void:
	if player.gold >= 50:
		$Buttons/_triple_antigens.queue_free()
		Upgrades.attack_upgrades["triple_antigens"] = true
		player.gold -= 50
		$GoldIndicator.text = "Gold = " + str(player.gold)
		_find_buttons()
	else:
		var _t_a_text = $Buttons/_triple_antigens.text
		$Buttons/_triple_antigens.text = "Insufficient Gold"
		await get_tree().create_timer(2.0).timeout
		$Buttons/_triple_antigens.text = _t_a_text

func _parry() -> void:
	if player.gold >= 100:
		Upgrades.action_upgrades["parry"] = true
		player.gold -= 100
		$GoldIndicator.text = "Gold = " + str(player.gold)
		_find_buttons()
		Events.allowed_actions["parry"] = true
		$Buttons/_parry.text = "Press space to parry!"
		await get_tree().create_timer(2.0).timeout
		$Buttons/_parry.queue_free()
	else:
		var _p_text = $Buttons/_parry.text
		$Buttons/_parry.text = "Insufficient Gold"
		await get_tree().create_timer(2.0).timeout
		$Buttons/_parry.text = _p_text
		
func _exploding_enemies() -> void:
	if player.gold >= 150:
		$Buttons/_exploding_enemies.queue_free()
		Upgrades.attack_upgrades["exploding_enemies_on_death"] = true
		player.gold -= 150
		$GoldIndicator.text = "Gold = " + str(player.gold)
		_find_buttons()
	else:
		var _e_e_text = $Buttons/_exploding_enemies.text
		$Buttons/_exploding_enemies.text = "Insufficient Gold"
		await get_tree().create_timer(2.0).timeout
		$Buttons/_exploding_enemies.text = _e_e_text
	
func _50_glucose() -> void:
	if player.gold >= 50:
		Upgrades.call("_50_glucose_regen")
		player.gold -= 50
		$GoldIndicator.text = "Gold = " + str(player.gold)
		_find_buttons()
	else:
		var f_g_text = $Buttons/_50_glucose.text
		$Buttons/_50_glucose.text = "Insufficient Gold"
		await get_tree().create_timer(2.0).timeout
		$Buttons/_50_glucose.text = f_g_text
