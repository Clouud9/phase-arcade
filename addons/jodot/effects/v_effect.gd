extends EffectSprite2D
class_name VFXSprite

var playing = false

var default_frame: int = 0
var default_flip_h: bool = false
var default_flip_v: bool = false
var default_visible: bool = true

signal expire
func _expire():
	playing = false
	expire.emit()

func stop():
	playing = false

## Randomize this sprite's orientation for the current play-through. Usually
## called immediately after acquiring the sprite. Pass [param horizontal] /
## [param vertical] as false to pin an axis.
func randomize_orientation(horizontal: bool = true, vertical: bool = true) -> void:
	flip_h = randf() > 0.5 if horizontal else false
	flip_v = randf() > 0.5 if vertical else false

## Restore the sprite to the state it was authored in. Called on acquisition so
## a recycled sprite never leaks orientation or frame state from its last use.
func reset_defaults() -> void:
	frame = default_frame
	flip_h = default_flip_h
	flip_v = default_flip_v
	visible = default_visible

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
	default_frame = frame
	default_flip_h = flip_h
	default_flip_v = flip_v
	default_visible = visible
	if texture:
		set_spritesheet(texture)
