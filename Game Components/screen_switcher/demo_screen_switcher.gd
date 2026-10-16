extends ScreenSwitcher

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Keys 1-9 map to the Screen1-Screen9 children (KEY_1..KEY_9 are
		# consecutive), so the demo works however many screens the scene has.
		var index: int = event.keycode - KEY_1
		var target := get_node_or_null("Screen%d" % (index + 1)) as Screen
		if target:
			toggle(target)
