extends Node3D

@export var circuit:StringName

func switch():
	if circuit != &"":
		HandyLight.register_circuit(circuit).state=true
	$AudioStreamPlayer3D.play()
	%Breakers_001.rotate_z(PI/2.2)

func _ready() -> void:
	$InteractZone.interacted.connect(switch)
