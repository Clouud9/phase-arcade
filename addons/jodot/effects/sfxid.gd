extends FXID
class_name SFXID

func play(n: Node) -> Variant:
	return Game.play_sfx(n, id) #HACK: we want to make this work standalone
