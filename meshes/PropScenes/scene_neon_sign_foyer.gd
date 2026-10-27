extends MeshInstance3D

@export var circuit:StringName

func set_power_state(state:bool):
	mesh.surface_get_material(0).set_shader_parameter("On", state)
	$SmNeonLogo.mesh.surface_get_material(0).set_shader_parameter("On", state)
	$SmNeonGlowPhaseArcade.visible = state
	%SmNeonGlowLogo.visible = state

func _ready() -> void:
	if circuit != &"":
		var switched = HandyLight.register_circuit(circuit)
		switched.to.connect(set_power_state)
		set_power_state(switched.state)
