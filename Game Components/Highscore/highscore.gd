class_name Highscore extends Resource
@export var player: String
@export var score: int

func _to_string() -> String:
	return "%s: %d" % [player, score]
