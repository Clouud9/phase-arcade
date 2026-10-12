@tool
class_name Curtain
extends ColorRect

enum {DOWN, UP, LEFT, RIGHT}
@export var duration := 0.5
@export var direction := UP
@export var open_on_ready := true

@export_tool_button("close", "ControlAlignCenter") var close_button = close
@export_tool_button("open", "ControlAlignFullRect") var open_button = open

var current_tween: Tween

## How closed the curtain is, 0 (open) to 1 (closed).
func get_openness() -> float:
	var f = material.get_shader_parameter("factor")
	return 1.0 - (f if f is float else 1.0)

## Sets how closed the curtain is, 0 (open) to 1 (closed).
func set_openness(f: float) -> void:
	material.set_shader_parameter("factor", 1.0 - f)

## True if the current material's shader has a [param param_name] uniform.
func has_param(param_name: StringName) -> bool:
	var m := material as ShaderMaterial
	if not m or not m.shader:
		return false
	for u in m.shader.get_shader_uniform_list():
		if u.name == param_name:
			return true
	return false

## Kills any wipe in progress and starts a fresh one.
func new_tween() -> Tween:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	return current_tween

func close(from_direction := direction, specific_duration := duration) -> Signal:
	_set_direction(from_direction)
	visible = true
	var t = new_tween()
	t.tween_method(set_openness, get_openness(), 0.0, specific_duration * get_openness())
	return t.finished

func open(to_direction := direction, specific_duration := duration) -> Signal:
	_set_direction(to_direction)
	var t = new_tween()
	t.tween_method(set_openness, get_openness(), 1.0, specific_duration * (1.0 - get_openness()))
	# hide once fully retracted, so it stops eating mouse input
	t.finished.connect(func (): visible = false)
	return t.finished

## Only set if the shader actually has the uniform, so swapping in the dither
## shader (which has no direction) stays quiet.
func _set_direction(dir: int) -> void:
	if has_param(&"direction"):
		material.set_shader_parameter("direction", dir)

func _ready() -> void:
	if open_on_ready:
		open()
