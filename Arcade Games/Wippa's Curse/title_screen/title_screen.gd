extends Game

## Emitted when a run ends, by either victory or defeat.
signal game_ended

@onready var game_cam:Camera3D = $Game.get_node("CharacterBody3D/Camera3D")

func set_title_active(state:bool):
	%TitleCam.current = state
	game_cam.current = !state
	$Game.process_mode = Node.PROCESS_MODE_DISABLED if state else Node.PROCESS_MODE_INHERIT
	%TitleUI.visible = state

func _ready() -> void:
	super()
	set_title_active(true)
	while true:
		var cab = ArcadeCabinet.get_cabinet(self)
		if cab:
			await cab.pop_coin()
			$InsertCoinAudio.play()
			await %Curtain.close()
		set_title_active(false)
		%Curtain.open()
		# The win/lose animations play out before game_ended fires
		await game_ended
		await %Curtain.close()
		_reload_game()
		set_title_active(true)
		%Curtain.open()

func win():
	super()
	game_ended.emit()

func lose():
	super()
	game_ended.emit()

# Replaces the game sub-scene with a fresh instance, resetting the level
# for the next coin. This also clears the win/lose fade overlays, so it
# must only be called while the curtain is closed.
func _reload_game() -> void:
	var old_game := $Game
	var game_scene:PackedScene = load(old_game.scene_file_path)
	var fresh_game := game_scene.instantiate()
	remove_child(old_game)
	old_game.queue_free()
	add_child(fresh_game)
	move_child(fresh_game, 0)
	game_cam = fresh_game.get_node("CharacterBody3D/Camera3D")
