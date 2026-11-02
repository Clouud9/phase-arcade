extends StaticBody3D

@export var sound_player: AudioStreamPlayer3D
var bumper_sound = preload("res://Arcade Games/AirHockey/BellHit-206700 - Railroad Crossing Signal Bell - Loop.wav")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sound_player.stream = bumper_sound
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_hit():
	sound_player.play()
	print("puckhit")
