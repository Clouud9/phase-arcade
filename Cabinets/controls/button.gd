extends Node

@export var push_button:NodePath
@onready var _btn:Node3D = get_node(push_button)

func _ready() -> void:
	pass # Replace with function body.

var direction:float
func press(f:float, delta:float, travel:float=0.004, speed:float=4):
	var curr_y = _btn.position.y
	_btn.position.y = move_toward(_btn.position.y, f * -travel, speed * delta)
	var curr_direction = curr_y - _btn.position.y
	if sign(direction) != sign(curr_direction):
		if sign(direction) > 0:
			$PressSFX.play()
		elif sign(direction) < 0:
			$ReleaseSFX.play()
	direction = curr_direction
