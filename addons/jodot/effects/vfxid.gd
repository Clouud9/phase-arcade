extends FXID
class_name VFXID

@export var random_flip = false
@export var invert = false

func play(n: Node) -> Variant:
	var fx = VFX.play(id, n)
	if random_flip:
		fx.randomize_orientation()
	if invert:
		fx.flip_v = true
	return fx

