@tool
extends Sprite2D

func _process(delta: float) -> void:
	var parent = get_parent()
	if parent is Sprite2D:
		flip_h = parent.flip_h
