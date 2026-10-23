extends Path2D

@onready var sound = get_tree().get_first_node_in_group("sound")

@onready var beat_area = $BeatArea/CollisionPolygon2D

var strength := 600.0
var beats_per_pump := 8.0
var pump_length := 1.0
