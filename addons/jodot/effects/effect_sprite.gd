extends Sprite2D
class_name EffectSprite2D

@export_range(0,16) var animation_frames: int = 0
@export_range(0, 60, 1, "suffix:fps") var animation_rate = 0
@export_range(0,16) var randomize_frames: int
@export_range(0, 60, 1, "suffix:fps") var randomize_rate = 0
@export_range(0, 60, 1, "suffix:fps") var strobe_rate = 0
@export var random_hflip = false
@export var random_vflip = false

func randomize_sprite(forbid_same_frame=false):
	if randomize_frames:
		var new_frame = -1
		while new_frame == -1 or (frame == new_frame and forbid_same_frame):
			new_frame = range(randomize_frames).pick_random()
		frame = new_frame
	if random_hflip:
		flip_h = randf() > 0.5
	if random_vflip:
		flip_v = randf() > 0.5

func advance_animation():
	if frame >= animation_frames - 1:
		frame = 0
	else:
		frame += 1

func strobe():
	visible = !visible

class _Animation:
	var start:int
	var frames:int
	var rate:float
	var accum:float
	var sprite:Sprite2D
	signal done

	func _init(start:int, frames:int, rate:float, sprite:Sprite2D):
		self.start = start
		self.frames = frames
		self.rate = rate
		self.sprite = sprite

	func add_time(delta: float):
		accum += delta
		sprite.frame = start + min(
			frames - 1,
			floor(accum * rate)
		)
		if accum >= frames / rate:
			done.emit()

var current_animation: _Animation = null
var cumers: Array[Cumer]
func _process(delta: float) -> void:
	if current_animation:
		current_animation.add_time(delta)
	else:
		for c in cumers:
			c.add(delta)

func reset_current_animation():
	current_animation = null

func play_animation(start:int, frames:int, rate:int) -> Signal:
	visible = true
	current_animation = _Animation.new(start, frames, rate, self)
	current_animation.done.connect(reset_current_animation)
	return current_animation.done

func reset() -> void:
	cumers.clear()
	if is_node_ready():
		_ready()

func _ready() -> void:
	randomize_sprite()
	if randomize_rate > 0:
		cumers.append(Cumer.new(randomize_rate, randomize_sprite.bind(true)))
	if animation_frames and animation_rate > 0:
		cumers.append(Cumer.new(animation_rate, advance_animation))
	if strobe_rate:
		cumers.append(Cumer.new(strobe_rate, strobe))
