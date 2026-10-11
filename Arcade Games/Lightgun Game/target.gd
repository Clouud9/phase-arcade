extends TextureButton

func _pressed() -> void:
	Game.get_game(self).add_score(1)
	Game.play_sfx(self, "bang")
	disabled = true
	await  reposition()
	disabled = false

func reposition():
	visible = false
	await Utils.delay(Yute.pick_random_exp([1.0, 0.8, 0.5, 0.1, 2.0]))
	var space = get_parent().get_global_rect()
	space.size -= get_global_rect().size
	global_position = Yute.random_point(space)
	Game.play_sfx(self, "blooph")
	visible = true

func _ready() -> void:
	reposition()
