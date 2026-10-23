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
