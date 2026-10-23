extends Node2D

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var shopkeeper = $Shopkeeper
@onready var shop_menu = $ShopMenu
var initial_dir
var activation_distance: float = 400.0
var pull_force = 200.0
var push_force = 4000.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Shopkeeper/AnimationPlayer.play("shopkeeper_idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
	if Vector2(shopkeeper.global_position - player.global_position).length() < activation_distance:
		$Label.text = "Press 'E' to open shop"
		player.velocity += Vector2(shopkeeper.global_position-player.global_position).normalized() * pull_force
		if Input.is_action_just_pressed("e"):
			shop_menu.visible = true
	else:
		$Label.text = ""
		initial_dir = (player.global_position-shopkeeper.global_position).normalized()

func _on_shop_menu_shop_exited() -> void:
	player.velocity += push_force * initial_dir

func save() -> Dictionary:
	var save_dict = {
		"filename": get_scene_file_path(),
		"parent": get_tree().current_scene.get_path_to(get_parent()),
		"initial_dir_x": initial_dir.x,
		"initial_dir_y": initial_dir.y,
		"shop_visible": shop_menu.visible
	}

	return save_dict

func load_data(data: Dictionary) -> void:
	initial_dir = Vector2(data["initial_dir_x"], data["initial_dir_y"])
	shop_menu.visible = data["shop_visible"]
