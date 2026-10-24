extends Label
class_name ScoreLabel

func set_score(i: int):
	text = "%03d" % i

func _ready():
	set_score(Game.get_game(self).score)
	Game.get_game(self).score_changed.connect(set_score)
