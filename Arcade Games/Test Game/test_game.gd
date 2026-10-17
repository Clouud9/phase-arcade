extends Game

func _ready() -> void:
	super()
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		$ScreenSwitcher.show_instant(%StartScreen)
		await cab.pop_coin()
	$ScreenSwitcher.show_screen(%GameScreen)
	await game_lost
	$ScreenSwitcher.show_screen(%EndScreen)
	await %EndScreen.done
	await %Curtain.close()
	%Curtain.open()
	_ready()
