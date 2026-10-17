extends Control

@onready var table:HighscoreContainer = $HighscoreContainer
@onready var new_score_label:Label = %NewScoreLabel
@onready var initials:Initials = %Initials

var new_score:Highscore

func _on_highscores_updated():
	new_score.player = initials.get_initials()
	new_score_label.text = "%d" % new_score.score
	table.populate()

func _ready() -> void:
	var game = Game.get_game(self)
	if game:
		new_score = Highscore.new()
		new_score.score = game.score
		table.highscore_collection.highscores.append(new_score)
		game.highscores_updated.connect(_on_highscores_updated)
		game.highscores_updated.emit()
