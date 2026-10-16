@tool
class_name Curtain
extends ColorRect

## The elapsed time of the current animation, in seconds.
## Will be equal to [code]get_openness() * duration[/code] when the blending
## function is linear
var time:float = 0

func _update_transition():
	_set_direction(transition.direction)
	time = Transition._calculate_time(transition, get_openness())
	
@export var transition:Transition:
	set(t):
		transition = t
		_update_transition()

@export var open_on_ready := true

@export_tool_button("open", "ControlAlignFullRect") var open_button = open
@export_tool_button("close", "ControlAlignCenter") var close_button = close

signal opened
signal closed

var opening:bool = true

## How closed the curtain is, from 0 to 1
func get_openness() -> float:
	var f = material.get_shader_parameter("factor")
	return 1.0 - (f if f is float else 1.0)

## Sets how closed the curtain is from 0 to 1
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

func close(override_transition:Transition=null) -> void:
	visible = true
	if override_transition:
		transition = override_transition
	opening = false
	# Already closed: nothing to wait for. (Skipping this would await `closed`
	# forever, since _process bails out once the transition is done.)
	if not is_transition_done():
		await closed

func open(override_transition:Transition=null) -> void:
	if override_transition:
		transition = override_transition
	opening = true
	if not is_transition_done():
		await opened
	visible = false
	
# Has no effect if the shader does not have a `direction` parameter
func _set_direction(dir: int) -> void:
	if has_param(&"direction"):
		material.set_shader_parameter("direction", dir)

func _ready() -> void:
	if not transition:
		transition = Transition.new()
	if open_on_ready:
		open()

func is_transition_done() -> bool:
	return (opening and get_openness() >= 1) or (not opening and get_openness() <= 0)

func _process(delta:float):
	_update_transition()
	if is_transition_done():
		return
	time += delta if opening else -delta
	set_openness(Transition._calculate_progress(transition, time))
	if is_transition_done():
		(opened if opening else closed).emit()
