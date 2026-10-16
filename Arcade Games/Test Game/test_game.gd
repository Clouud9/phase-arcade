extends Game

var game_on = false

func _ready() -> void:
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		$ScreenSwitcher.show_instant(%StartScreen)
		await cab.pop_coin()
		game_on = true
	$ScreenSwitcher.show_screen(%GameScreen)
	await game_lost
	await %Curtain.close()
	%Curtain.open()
	_ready()
