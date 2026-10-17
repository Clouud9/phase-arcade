@tool
extends Screen
## A [Screen] which spawn a scene when visible and clears the scene when not visible

@export var scene:PackedScene
var current_scene

func _set_shown(shown:bool):
	super(shown)
	if current_scene:
		current_scene.free()
	if shown:
		current_scene = scene.instantiate()
		add_child(current_scene)
