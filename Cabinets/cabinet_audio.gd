extends AudioStreamPlayer3D
class_name ArcadeCabinetAudio
## This is all clanker code. I'm actually amazed how well it works. It beat the expectations of the Godot docs by quite a margin. Still, it might have to be thrown out if it turns out to choke the real setting when there are multiple cabinets going

const GAME_BUS := &"Game"
const CAPTURE_EFFECT := 0
const CAPTURE_BUFFER := 0.1
const PUMP_PERIOD := 2
const MAX_LATENCY := 0.02
const MAX_LATENCY_NO_THREADS := 0.08

var capture: AudioEffectCapture
var playback: AudioStreamGeneratorPlayback
var capacity := 0
var budget := 0
var pump_thread: Thread
var pumping := false

func _ready() -> void:
	var bus_index := AudioServer.get_bus_index(GAME_BUS)
	if bus_index < 0:
		push_error("no audio bus named %s" % GAME_BUS)
		return
	capture = AudioServer.get_bus_effect(bus_index, CAPTURE_EFFECT) as AudioEffectCapture
	if capture == null:
		push_error("bus %s has no AudioEffectCapture at effect %d" % [GAME_BUS, CAPTURE_EFFECT])
		return

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = maxf(AudioServer.get_mix_rate(), 8000.0)
	generator.buffer_length = CAPTURE_BUFFER
	stream = generator
	play()
	playback = get_stream_playback()
	capacity = playback.get_frames_available()

	pumping = true
	if OS.has_feature("thread"):
		budget = mini(int(MAX_LATENCY * generator.mix_rate), capacity)
		pump_thread = Thread.new()
		if pump_thread.start(_pump_loop) != OK:
			pump_thread = null
	else:
		budget = mini(int(MAX_LATENCY_NO_THREADS * generator.mix_rate), capacity)

func _pump() -> void:
	var used := capacity - playback.get_frames_available()
	var available := capture.get_frames_available()
	var stale := used + available - budget
	if stale > 0 and available > 0:
		var drop := mini(stale, available)
		capture.get_buffer(drop)
		available -= drop
	var frames := mini(playback.get_frames_available(), available)
	if frames > 0:
		playback.push_buffer(capture.get_buffer(frames))

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
