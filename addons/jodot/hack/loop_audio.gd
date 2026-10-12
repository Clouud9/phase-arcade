@tool
extends AudioStreamPlayer2D

func play_after_delay():
	await get_tree().create_timer(1).timeout
	play()

func _ready():
	play()
	finished.connect(play_after_delay)
