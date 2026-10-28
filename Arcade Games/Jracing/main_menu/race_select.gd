extends Button

@export var track: TrackData

func _pressed() -> void:
	MenuBeep.play_for(self)
	RaceManager.track_data = track
	get_tree().change_scene_to_file("res://race/race.tscn")
