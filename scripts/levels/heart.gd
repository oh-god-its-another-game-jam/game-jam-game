extends Node2D

func _ready() -> void:
	Events.soundtrack_request.emit("res://sounds/Tenebre_Rosso_Sangue.mp3")
