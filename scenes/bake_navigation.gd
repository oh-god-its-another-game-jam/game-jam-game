extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$NavigationRegion2D.bake_finished.connect(_on_bake_finished)
	$NavigationRegion2D.bake_navigation_polygon()


func _on_bake_finished() -> void:
	var region = $NavigationRegion2D
	var polygon = region.navigation_polygon

	print("Navigation baking finished!")
	print("Outline count: ", polygon.get_outline_count())
	print("Polygon count: ", polygon.get_polygon_count())
	print("Navigation map: ", region.get_navigation_map())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
