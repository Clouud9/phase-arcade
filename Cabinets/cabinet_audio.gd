extends AudioStreamPlayer3D
class_name ArcadeCabinetAudio
## This is all clanker code. I'm actually amazed how well it works. It beat the
## expectations of the Godot docs by quite a margin. Still, it might have to be thrown out if it turns out to choke in the real setting when there are multiple cabinets, and one thread to serve them all..

const CAPTURE_EFFECT := 0
const CAPTURE_BUFFER := 0.1
const PUMP_PERIOD := 2
const MAX_LATENCY := 0.02
const MAX_LATENCY_NO_THREADS := 0.08

## Split the game's stereo mix across two emitters, one per channel, for a wider
## cabinet. Off by default: it costs a second player, a second generator and a
## per-frame de-interleave, which matters on single-threaded web builds.
@export var stereo_output := false
## Distance in metres between this emitter and the right one when [member stereo_output] is on.
@export_range(0.0, 1.0, 0.01) var stereo_separation := 0.25

## Name of the private bus this cabinet's game audio is routed through.
## Empty if the bus could not be created, in which case game audio is left alone.
var bus_name: StringName = &""

var capture: AudioEffectCapture
var playback: AudioStreamGeneratorPlayback
var right_playback: AudioStreamGeneratorPlayback
var right_speaker: AudioStreamPlayer3D
var capacity := 0
var budget := 0
var pump_thread: Thread
var pumping := false

static var _next_bus_id := 0

func _ready() -> void:
	_create_bus()
	if capture == null:
		return

	var mix_rate := maxf(AudioServer.get_mix_rate(), 8000.0)
	playback = _start_generator(self, mix_rate)

	if stereo_output:
		right_speaker = AudioStreamPlayer3D.new()
		right_speaker.name = "RightSpeaker"
		right_speaker.transform = Transform3D(Basis(), Vector3(stereo_separation, 0, 0))
		right_speaker.attenuation_model = attenuation_model
		right_speaker.unit_size = unit_size
		right_speaker.max_distance = max_distance
		add_child(right_speaker)
		right_playback = _start_generator(right_speaker, mix_rate)

	capacity = playback.get_frames_available()

	pumping = true
	if OS.has_feature("thread"):
		budget = mini(int(MAX_LATENCY * mix_rate), capacity)
		pump_thread = Thread.new()
		if pump_thread.start(_pump_loop) != OK:
			pump_thread = null
	else:
		budget = mini(int(MAX_LATENCY_NO_THREADS * mix_rate), capacity)

# --- Bus ---

func _create_bus() -> void:
	_next_bus_id += 1
	bus_name = StringName("Cabinet_%d" % _next_bus_id)
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, &"Master")
	AudioServer.set_bus_mute(bus_index, true)
	var effect := AudioEffectCapture.new()
	effect.buffer_length = CAPTURE_BUFFER
	AudioServer.add_bus_effect(bus_index, effect, CAPTURE_EFFECT)
	capture = AudioServer.get_bus_effect(bus_index, CAPTURE_EFFECT) as AudioEffectCapture
	if capture == null:
		bus_name = &""
		push_error("%s: failed to create capture bus" % name)

func _remove_bus() -> void:
	if bus_name == &"":
		return
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index > 0:
		AudioServer.remove_bus(bus_index)
	bus_name = &""

# --- Audio pumping ---

func _start_generator(player: AudioStreamPlayer3D, mix_rate: float) -> AudioStreamGeneratorPlayback:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = mix_rate
	generator.buffer_length = CAPTURE_BUFFER
	player.stream = generator
	player.play()
	return player.get_stream_playback() as AudioStreamGeneratorPlayback

func _pump() -> void:
	if capture == null:
		return
	var used := capacity - playback.get_frames_available()
	var available := capture.get_frames_available()
	var stale := used + available - budget
	if stale > 0 and available > 0:
		var drop := mini(stale, available)
		capture.get_buffer(drop)
		available -= drop
	var frames := mini(playback.get_frames_available(), available)
	if right_playback:
		frames = mini(frames, right_playback.get_frames_available())
	if frames <= 0:
		return
	var buffer := capture.get_buffer(frames)
	if right_playback == null:
		playback.push_buffer(buffer)
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	left.resize(frames)
	right.resize(frames)
	for i in frames:
		left[i] = Vector2(buffer[i].x, buffer[i].x)
		right[i] = Vector2(buffer[i].y, buffer[i].y)
	playback.push_buffer(left)
	right_playback.push_buffer(right)

func _pump_loop() -> void:
	while pumping:
		_pump()
		OS.delay_msec(PUMP_PERIOD)

func _process(_delta: float) -> void:
	if playback == null or pump_thread:
		return
	_pump()

func _exit_tree() -> void:
	pumping = false
	if pump_thread:
		pump_thread.wait_to_finish()
		pump_thread = null
	_remove_bus()
