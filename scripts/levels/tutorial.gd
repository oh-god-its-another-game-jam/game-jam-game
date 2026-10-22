extends Node2D

@onready var instructor: Label = $CanvasLayer/Instructor
@onready var test1 = $ExampleIcon1/Area2D
@onready var godot_icon = $ExampleIcon1

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var cell = preload("res://scenes/cell.tscn")
@onready var enemy = preload("res://scenes/enemy_stuff/basic_enemy.tscn")

# Godot functions

func _ready() -> void:
	tutorial()

# User functions

func show_line(text: String, hold: bool = false, hold_time := 1.5):
	instructor.text = text
	if hold:
		await get_tree().create_timer(hold_time).timeout

func tutorial() -> void:
	await show_line("Hello there; welcome to our game", true, 3)
	
	Events.allowed_actions["move"] = true
	await show_line("Use WASD to move", true, 2.0)
	await show_line("Move over to the Godot icon")
	await test1.body_entered
	await show_line("Well done!", true, 2.0)
	
	Events.allowed_actions["shoot"] = true
	await show_line("Left click to shoot")
	await Events.player_shoot
	await show_line("Well done!", true, 2.0)
	
	Events.allowed_actions["dash"] = true
	await show_line("Right click to dash")
	await Events.dash_sound
	await show_line("Well done!\nAttacks cannot hit you when you're dashing", true, 2.0)
	
	Events.allowed_actions["toggle_minimap"] = true
	await show_line("Press M to toggle the minimap", false, 2.0)
	await Events.minimap_toggle
	await show_line("Well done!", true, 2.0)
	
	godot_icon.hide()
	cell = cell.instantiate()
	cell.controlled_by = "player"
	cell.global_position = player.global_position + Vector2(200,0)
	get_parent().add_child(cell)
	
	await show_line("This is a cell. \nThis is what it looks like when you control it",true,2.0)
	cell.controlled_by = "enemy"
	await show_line("And this is what it looks like \nwhen it is controlled by the enemy",true,2.0)
	await show_line("When controlled by the enemy, it acts\n as a spawner",true,2.0)
	await show_line("Attack the cell to win it!",false,2.0)
	await cell.captured_by_player
	await show_line("Well Done!",true,2.0)
	
	await show_line("If you stay close to your cell, it\nwill heal you",true,2.0)
	
	cell.queue_free()
	
	await show_line("Speaking of enemies, let's meet one",true,2.0)
	await show_line("Kill the enemy!",false,2.0)
	enemy = enemy.instantiate()
	enemy.global_position = player.global_position + Vector2(200,0)
	get_parent().add_child(enemy)
	await Events.enemy_died_sound
	await show_line("Good Job! In-game they move, I promise!",true,2.0) # Keep them not moving? If you disagree, then just add a navigation region
	
	await show_line("Enemies can also regen near their cells.\nIf you control a cell, the enemy\nwill attack it",true,3.0)
	await show_line("Larger enemies are better, \nso be careful with them!",true,2.0)
	
	await show_line("You're ready for the real game now!\nGood luck, we hope you enjoy it!", true, 2.0)
	get_tree().change_scene_to_file("res://scenes/ui/main-menu.tscn")

# obligatory pf 🏳️‍🌈
