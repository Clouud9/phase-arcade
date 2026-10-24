extends Game

func _ready() -> void:
	super()
	while true:
		await %StartScreen.open_dialogue()
		$ScreenSwitcher.show_screen(%GameScreen)
		await game_lost
		await %EndScreen.open_dialogue()
		await %Curtain.close()
		save_highscores()
		%Curtain.open()
