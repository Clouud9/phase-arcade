extends Node3D
class_name ControlPlane
## THis node has a description

var input_tracker:InputTracker
func _ready():
	var cab = ArcadeCabinet.get_cabinet(self)
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
