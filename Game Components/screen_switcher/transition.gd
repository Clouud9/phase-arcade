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

## static version of [method blend]
static func _blend(transition:Transition, t:float) -> float:
	match transition.blending_function:
		BLEND_FUNC.SMOOTH:
			return smoothstep(0.0, 1.0, t)
		_:
			return t

## Shapes a raw 0..1 [param t] through [member blending_function].
func blend(t:float) -> float:
	return _blend(self, t)

## static version of [method unblend]
static func _unblend(transition:Transition, progress:float) -> float:
	progress = clampf(progress, 0.0, 1.0)
	match transition.blending_function:
		BLEND_FUNC.SMOOTH:
			# Inverse of smoothstep's 3t^2 - 2t^3 polynomial.
			return 0.5 - sin(asin(1.0 - 2.0 * progress) / 3.0)
		_:
			return progress

## The inverse of [method blend]: recovers the raw 0..1 time that would shape
## to [param progress]. Clamps [param progress] to the valid range.
func unblend(progress:float) -> float:
	return _unblend(self, progress)


## True if this transition should be applied with no animation at all.
func is_instant() -> bool:
	return mode == Mode.NONE or duration <= 0.0
