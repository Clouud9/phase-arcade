extends AudioStreamPlayer
class_name MenuBeep

static func play_for(from: Node) -> void:
	var game := Game.get_game(from)
	if game == null:
		push_error("MenuBeep.play_for called outside a Game scene.")
		return

	var player := game.get_node_or_null("MenuBeep") as AudioStreamPlayer
	if player == null:
		push_error("Game scene is missing its MenuBeep player.")
		return
	player.play()

func _ready() -> void:
	stream = preload("res://Arcade Games/Jracing/ui_common/beep.wav")
