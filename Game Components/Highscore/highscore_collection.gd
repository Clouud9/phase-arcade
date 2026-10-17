class_name HighscoreCollection extends Resource
@export var highscores:Array[Highscore]

func _to_string() -> String:
	var lines := PackedStringArray()
	for highscore in highscores:
		lines.append(str(highscore))
	return "\n".join(lines)
