extends Node

func play(audio:AudioStream, single=false,random_shift=false):
	if not audio:
		return
	if single:
		stop()
	
	for player:AudioStreamPlayer in get_children():
		if not player.playing:
			player.stream = audio
			if random_shift:
				player.pitch_scale = randf_range(0.8,1.2)
			player.play()
			player.finished.connect(func():player.pitch_scale = 1)
			break
	
func stop():
	for player:AudioStreamPlayer in get_children():
		player.stop()
