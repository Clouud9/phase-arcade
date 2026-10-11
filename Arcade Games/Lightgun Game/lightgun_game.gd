extends Game

func _input(ev:InputEvent):
	if ev is InputEventMouseButton and ev.is_pressed():
		VFX.play("snap", self, ev.position)
		$SFXPlayer.play_sfx("pistol")
