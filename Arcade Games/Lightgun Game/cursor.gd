extends Control

func _process(delta: float) -> void:
	position = ArcadeCabinet.get_input_state(self).cursor_pos
