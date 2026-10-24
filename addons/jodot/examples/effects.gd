extends Control

func random_pos():
	return Vector2(size.x * randf(), size.y * randf())
func spawn_vfx():
	var v = VFX.play(["pop", "bang", "snap"].pick_random(), self, random_pos())
	v.randomize_orientation()

func _process(delta):
	spawn_vfx()
