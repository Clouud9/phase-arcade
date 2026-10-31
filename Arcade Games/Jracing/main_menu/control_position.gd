extends Control

@export var top: float = 0

func _process(_delta: float) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	position = Vector2(0, screen_size.y * top)
	size = Vector2(screen_size.x, screen_size.y * 0.5)
