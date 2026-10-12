extends Node3D
class_name ControlPlane
## The cabinet's physical controls (joystick, fire/bomb buttons, lightgun).
## Drives their visuals from the state tracked by [InputTracker].

var cab:ArcadeCabinet
var input_tracker:InputTracker
func _ready():
	cab = ArcadeCabinet.get_cabinet(self)
	if not cab.is_node_ready():
		print("cabbie is sleepy")
		await cab.ready
	input_tracker = cab.input_tracker

func fbool(b:bool) -> float:
	return 1.0 if b else 0.0

func _process(delta: float) -> void:
	$Joystick.deflect(input_tracker.movement, delta)
	$FireButton.press(fbool(input_tracker.firing), delta, 0.004, 4)
	$BombButton.press(fbool(input_tracker.bombing), delta, 0.003, 4)
	$Lightgun.look_at(cab.cursor_pos)
