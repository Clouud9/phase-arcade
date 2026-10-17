extends Button
class_name SubmitButton
## A [Button] which triggers [signal Screen.done] when pressed, if it is a child of a [Screen]

func _ready() -> void:
	var screen = Screen.get_screen(self)
	if screen:
		pressed.connect(screen.done.emit)
