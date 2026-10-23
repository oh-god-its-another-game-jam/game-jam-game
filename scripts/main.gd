extends Node2D

@onready var player = $"../Player"
@onready var boss = $"../Organs/Heart/Boss"

var check_timer: Timer

func _ready() -> void:
	check_timer = Timer.new()
	check_timer.wait_time = 1
	check_timer.autostart = true
	check_timer.one_shot = false
	check_timer.timeout.connect(_check)
	add_child(check_timer)

func _check() -> void:
	for area in get_children():
		if area is Area2D and area.overlaps_body(player):
			match area.name:
				"Brain":
					Events.level = Events.Levels.brain
				"Liver":
					Events.level = Events.Levels.liver
				"Intestines":
					Events.level = Events.Levels.intestines
				"Kidneys":
					Events.level = Events.Levels.kidneys
				"Appendix":
					Events.level = Events.Levels.appendix
				"Heart":
					boss.heart_activated = true
					Events.level = Events.Levels.heart
				"Lungs":
					Events.level = Events.Levels.lungs
