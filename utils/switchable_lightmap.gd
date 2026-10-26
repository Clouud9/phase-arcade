extends LightmapGI
class_name SwitchableLightmap

@export var circuit:StringName

func _on_circuit_switched(state:bool):
	light_data = initial_lmbake if state else null

var initial_lmbake:LightmapGIData

func _ready():
	initial_lmbake = light_data
	if circuit != &"":
		var switched = HandyLight.register_circuit(circuit)
		switched.to.connect(_on_circuit_switched)
		_on_circuit_switched(switched.state)
