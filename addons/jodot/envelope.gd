extends Resource
class_name Envelope

@export_range(0, 10, 0.01, "suffix:s") var attack = 0.0
@export_range(0, 10, 0.01, "suffix:s") var decay = 0.0
@export_range(0, 1) var sustain = 1.0
@export_range(0, 10, 0.01, "suffix:s") var release = 0.0

func value(active_time: float, inactive_time:float = -1) -> float:
	if inactive_time < 0:
		if active_time < attack:
			assert(attack > 0)
			return active_time/attack
		active_time -= attack
		if active_time < decay:
			assert(decay > 0)
			return lerp(1.0, sustain, active_time/decay)
		active_time -= decay
		return sustain
	else:
		if inactive_time < release:
			assert(release > 0)
			return lerp(value(active_time, -1), 0.0, inactive_time/release)
		return 0
