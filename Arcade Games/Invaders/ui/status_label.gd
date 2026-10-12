extends Label

func _on_win():
	text = "You Win!"

func _on_lose():
	text = "Game Over"

func _ready():
	text = ""
	Game.get_game(self).game_won.connect(_on_win)
	Game.get_game(self).game_lost.connect(_on_lose)
