extends Game

var game_on = false

func title_loop():
	%TitleScreen.present(1.0, Vector2.ZERO)
	await get_tree().create_timer(6).timeout
	while not game_on:
		var curr = $ScreenSwitcher.current_screen()
		if curr == %TitleScreen:
			$ScreenSwitcher.show_screen(%HighscoreScreen)
		else:
			$ScreenSwitcher.show_screen(%TitleScreen)
		await get_tree().create_timer(6).timeout

func _ready() -> void:
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		title_loop()
		await cab.pop_coin()
		game_on = true
	$ScreenSwitcher.show_screen(%GameScreen)
