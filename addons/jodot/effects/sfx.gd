extends Node
class_name SFXPlayer
## Loads your sound effects libraries at startup,
## and plays any track given the basename of the file.
## Can play 8 sounds concurrently. If you need more than that, you're crazy.

## searched recursively for audio files.
@export var audio_dirs: Array[String] = [
	"res://audio/chip_synth",
	"res://audio/warioware_diy"
]

var sfx:Dictionary[StringName,AudioStream]

func add_audio_directory(dir:String):
	for f in ResourceLoader.list_directory(dir):
		var res_name = "%s/%s" % [dir, f]
		if f.ends_with(".wav") or f.ends_with(".mp3") or f.ends_with("*.ogg"):
			var res = ResourceLoader.load(res_name)
			if res:
				var key = f.get_basename()
				assert(key)
				if sfx.has(key):
					print("Warn: deuplicate sfx entry for ",key)
				sfx[key] = res
		else:
			add_audio_directory(res_name)

func get_playback() -> AudioStreamPlaybackPolyphonic:
	if not get_player().has_stream_playback():
		get_player().play()
	return get_player().get_stream_playback()

## Used to control audio played by [SFXPlayer]
class SFXControl:
	var master
	var id
	var label: String
	func _init(master:AudioStreamPlaybackPolyphonic , id: int, label: String):
		self.master = master
		self.id = id
		self.label = label

	## Will be false if the stream has already finished playing
	func valid() -> bool:
		return master.is_stream_playing(id)

	## Returns false if not valid
	func set_volume(volume_db: float) -> bool:
		if not valid():
			return false
		master.set_stream_volume(id, volume_db)
		return true

	func stop():
		master.stop_stream(id)

## Plays an audio clip from the sfx library given the basename of the file.
## The basename is the filename without the extension, so
## [code]res://audio/pop.wav[/code] would have the [param effect_name] [code]"pop"[/code]
func play_sfx(effect_name:String) -> SFXControl:
	if not sfx.has(effect_name):
		print("Warn: no sfx named %s" % effect_name)
		return null

	var pb = get_playback()
	if not pb:
		print("Warn: audio is fucked while attempting to play %s" % effect_name)
		return null

	return SFXControl.new(pb, pb.play_stream(sfx[effect_name]), effect_name)

## Get's either [AudioStreamPlayer], [AudioStreamPlayer2D], or [AudioStreamPlayer3D],
## depending on which type of node this is
func get_player() -> Node:
	for p in [_self_player, _self_2D, _self_3D]:
		if p:
			assert(p.has_method("play"))
			assert("stream" in p)
			return p
	return null

# Today we're going to learn how to trick Godot into letting you do multiple inheritence
var _self_player:AudioStreamPlayer
var _self_2D:AudioStreamPlayer2D
var _self_3D:AudioStreamPlayer3D

func _ready():
	var _self = self as Node
	if _self is AudioStreamPlayer:
		_self_player = _self
	elif _self is AudioStreamPlayer2D:
		_self_2D = _self
	elif _self is AudioStreamPlayer3D:
		_self_3D = _self
	else: # In the case of autoload
		_self_player = AudioStreamPlayer.new()
		add_child(_self_player)
		print("created new global ",_self_player)

	for dir in audio_dirs:
		add_audio_directory(dir)
	print(self,": added %d entries to sfx library" % sfx.size())
	get_player().stream = AudioStreamPolyphonic.new()
	get_player().stream.polyphony = 8
