extends Button

func _ready() -> void:
	var screen = Screen.get_screen(self)
	if screen:
		pressed.connect(screen.done.emit)
