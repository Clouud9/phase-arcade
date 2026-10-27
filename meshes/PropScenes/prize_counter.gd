extends Node3D

@export var circuit:StringName

func set_power_state(state:bool):
	$PrizeCounter_Glow.visible=state

func _ready() -> void:
	if circuit != &"":
		var switched = HandyLight.register_circuit(circuit)
		switched.to.connect(set_power_state)
		set_power_state(switched.state)
