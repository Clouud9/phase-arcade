extends Label
@export var timer:Timer

func _process(delta: float) -> void:
	if timer:
		text = "%10.2f" % timer.time_left
