extends Node2D

var button_index = 0
@onready var button_indicator = $CanvasLayer/SelectedButtonIndicator
@onready var buttons = $CanvasLayer/Buttons.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
	
	if Input.is_action_just_pressed("ui_accept"):
		call(buttons[button_index].name)

func _main_menu():
	get_tree().change_scene_to_file("res://scenes/ui/main-menu.tscn")
func _quit_game():
	get_tree().quit()
