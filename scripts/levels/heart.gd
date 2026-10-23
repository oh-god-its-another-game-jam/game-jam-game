extends Node2D

func _ready() -> void:
	Events.soundtrack_request.emit("res://sounds/Tenebre_Rosso_Sangue.mp3")
	get_tree().get_first_node_in_group("Player").in_heart_stream = true
