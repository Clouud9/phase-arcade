extends Control

## Show a the given screen using its defined transition.
## If [param screen] is [code]null[/code], it will play the current screen's transition in reverse
## and show nothing
func show_screen(screen:Screen):
	for c in get_children():
		if c is Screen:
			c.visible = c == screen

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_1:
			show_screen($Screen1)
		if event.keycode == KEY_2:
			show_screen($Screen2)
		if event.keycode == KEY_3:
			show_screen($Screen3)
