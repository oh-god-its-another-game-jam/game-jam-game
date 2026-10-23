extends Path2D

@onready var sound = get_tree().get_first_node_in_group("sound")

@onready var beat_area = $BeatArea

var strength := 600.0
var beats_per_pump := 8.0
var pump_length := 1.0

func _ready() -> void:
	await get_tree().physics_frame
	for body in beat_area.get_overlapping_bodies():
		if body.is_in_group("Player"):
			body.in_heart_stream = true


func get_beat() -> float:
	var time := fposmod(sound.beat_position, beats_per_pump)
	return pow(clampf(1-time/pump_length, 0.0, 1.0), 2.0) # i dont really know what this does but i hope it works

func get_push(world_pos: Vector2) -> Vector2: # well this is apparently the way to do this
	var closest_offset_on_path := curve.get_closest_offset(to_local(world_pos))
	var total_path_length := curve.get_baked_length()
	var look_ahead_distance := 5.0

	var path_point_behind: Vector2
	var path_point_ahead: Vector2
	if closest_offset_on_path + look_ahead_distance <= total_path_length:
		path_point_behind = curve.sample_baked(closest_offset_on_path)
		path_point_ahead = curve.sample_baked(closest_offset_on_path + look_ahead_distance)
	else:
		path_point_behind = curve.sample_baked(closest_offset_on_path - look_ahead_distance)
		path_point_ahead = curve.sample_baked(closest_offset_on_path)

	var flow_direction := global_transform.basis_xform(path_point_ahead - path_point_behind).normalized()
	return flow_direction * strength * get_beat()
