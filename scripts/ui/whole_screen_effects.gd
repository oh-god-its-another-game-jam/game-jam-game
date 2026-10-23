extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

var _tween: Tween

func _ready() -> void:
	rect.visible = false
	Events.screen_ripple.connect(_screen_ripple)

func _screen_ripple(screen_pos: Vector2) -> void:
	var material := rect.material as ShaderMaterial
	var uv := screen_pos / get_viewport().get_visible_rect().size

	if _tween and _tween.is_valid():
		_tween.kill()

	material.set_shader_parameter("origin", uv)
	material.set_shader_parameter("progress", 0.0)
	rect.visible = true

	_tween = create_tween()
	_tween.tween_property(material, "shader_parameter/progress", 1.0, 1.5)
	_tween.finished.connect(func(): rect.visible = false)
