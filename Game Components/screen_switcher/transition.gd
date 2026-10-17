extends Resource
class_name Transition

enum Mode {
	NONE, ## Visible instantly
	CURTAIN, ## The [Curtain] closes and opens
	MOVE_ONTOP, ## The new screen moves into the space of the old screen, like a card.
	MOVE_ACROSS ## The old screen moves aside for the new screen, like a camera pan
}
## The effect used to show and hide the owning [Screen].
@export var mode:Mode = Mode.NONE

enum DIR {DOWN, UP, LEFT, RIGHT}

## The direction of the transition. Not all transitions necessarily have a
## direction, and the precise meaning may vary between implementations.
@export var direction:DIR = DIR.UP

## Duration of the transition effect.
## Note that the [enum Transition.CURTAIN] effect plays twice so the overall time will be double
@export_range(0, 5, 0.1) var duration = 0.5

## The unit vector for [member direction], pointing toward the edge a screen
## exits by. An entering screen starts at the negation of it.
func travel() -> Vector2:
	match direction:
		DIR.DOWN:
			return Vector2(0, 1)
		DIR.UP:
			return Vector2(0, -1)
		DIR.LEFT:
			return Vector2(-1, 0)
		DIR.RIGHT:
			return Vector2(1, 0)
	return Vector2.ZERO

enum BLEND_FUNC {LINEAR, SMOOTH}
@export var blending_function:BLEND_FUNC = BLEND_FUNC.SMOOTH

## static version of [method calculate_progress]
static func _calculate_progress(transition:Transition, time:float) -> float:
	var t:float
	if transition.duration > 0.0:
		t = clampf(time / transition.duration, 0.0, 1.0)
	else:
		# Instant transition: any elapsed time at all is fully in.
		t = 1.0 if time > 0.0 else 0.0
	match transition.blending_function:
		BLEND_FUNC.SMOOTH:
			return smoothstep(0.0, 1.0, t)
		_:
			return t

## Progress of the transition from 0.0 to 1.0 [param time] seconds into it.
## Factors in [member duration] and [member blending_function].
func calculate_progress(time:float) -> float:
	return _calculate_progress(self, time)

## static version of [method calculate_time]
static func _calculate_time(transition:Transition, progress:float) -> float:
	progress = clampf(progress, 0.0, 1.0)
	match transition.blending_function:
		BLEND_FUNC.SMOOTH:
			# Inverse of smoothstep's 3t^2 - 2t^3 polynomial.
			return transition.duration * (0.5 - sin(asin(1.0 - 2.0 * progress) / 3.0))
		_:
			return transition.duration * progress

## The inverse of [method calculate_progress]: the elapsed time in seconds at
## which the transition reaches [param progress]. Clamps [param progress] to the
## valid range.
func calculate_time(progress:float) -> float:
	return _calculate_time(self, progress)

## True if this transition should be applied with no animation at all.
func is_instant() -> bool:
	return mode == Mode.NONE or duration <= 0.0
