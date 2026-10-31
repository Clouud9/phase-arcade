extends Button

@export var track: TrackData

func _pressed() -> void:
	MenuBeep.play_for(self)
	RaceManager.track_data = track
	JracingGame.switch_to(self, JracingGame.RACE_SCENE)
