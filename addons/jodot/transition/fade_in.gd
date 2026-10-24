class_name FadeIn
extends AudioStreamPlayer

## Fades a clip in from silence when it enters the tree, for stitching music
## into a scene change. Assign the stream in the inspector.

## Seconds spent fading from silence to full volume.
@export_range(0.1, 20.0, 0.1, "suffix:s") var fade_duration := 2.0

## The volume in dB to start from. Very low rather than truly silent, so
## [member AudioStreamPlayer.play] doesn't skip the first samples outright.
@export_range(-80.0, 0.0, 1.0) var start_db := -40.0

func _ready() -> void:
	volume_db = start_db
	var t = create_tween()
	t.tween_property(self, "volume_db", 0.0, fade_duration)
