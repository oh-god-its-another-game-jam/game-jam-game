extends CanvasLayer

@onready var character = get_tree().get_first_node_in_group("Player")

@onready var notifier = $Notifications

# --- HEALTH AND GLUCOSE ---
@onready var health_bar: TextureProgressBar = $HealthBar

@onready var boss_bar: TextureProgressBar = $BossBar

# Godot functions

func _ready() -> void:
	character.health_changed.connect(_on_health_change)
	Events.boss_health_changed.connect(_on_boss_health_change)
	boss_bar.hide()

# User functions

func _on_health_change(new: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = new

func _on_boss_health_change(new: float, max_value: float, visible: bool = false) -> void:
	if visible:
		boss_bar.show()
	elif not visible:
		boss_bar.hide()
	boss_bar.max_value = max_value
	boss_bar.value = new

func _notify(text: String, hold: bool = false, hold_time := 1.5):
	notifier.text = text
	if hold:
		await get_tree().create_timer(hold_time).timeout

func save() -> Dictionary:
	var save_dict = {
		"filename": get_scene_file_path(),
		"parent": get_tree().current_scene.get_path_to(get_parent()),
		"pos_x": null,
		"health_bar_progression": health_bar.value,
		"glucose_bar_progression": $GlucoseBottle.percentage,
		"boss_bar_progression": boss_bar.value,
	}
	return save_dict

func load_data(data: Dictionary) -> void:
	health_bar.value = data["health_bar_progression"]
	$GlucoseBottle.percentage = data["glucose_bar_progression"]
	boss_bar.value = data["boss_bar_progression"]
# obligatory pf 🏳️‍🌈
