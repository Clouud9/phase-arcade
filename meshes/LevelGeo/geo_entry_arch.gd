extends Node3D

@export var circuit:StringName

func set_power_state(state:bool):
	if not $EntryArch.is_node_ready():
		await $EntryArch.ready
	$EntryArch.get_surface_override_material(0).set_shader_parameter("On", state)
	print($EntryArch.get_surface_override_material(0).get_shader_parameter("On"))

func _ready() -> void:
	if circuit != &"":
		var switched = HandyLight.register_circuit(circuit)
		switched.to.connect(set_power_state)
		set_power_state(switched.state)
