extends EffectSprite2D
class_name VFXSprite

var playing = false

signal expire
func _expire():
	playing = false
	expire.emit()

func stop():
	playing = false

func play(s: VFX.Subframes, loops:int = 1):
	assert(not playing)
	playing = true
	if s.spritesheet:
		set_spritesheet(s.spritesheet)
	while playing:
		for i in range(s.end - s.start + 1):
			frame = s.start + i
			await get_tree().create_timer(1.0/s.rate).timeout
			if not playing:
				break
		loops -= 1
		if not playing:
			break
		playing = loops != 0 #therefore negative numbers loop infinitely
	_expire()

func set_spritesheet(t:Texture2D):
	texture = t
	hframes = texture.get_size().x / texture.get_size().y

func _ready():
	if texture:
		set_spritesheet(texture)
