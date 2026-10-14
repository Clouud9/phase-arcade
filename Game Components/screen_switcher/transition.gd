extends Resource
class_name Transition

enum Mode {
	NONE, ## Visible instantly
	CURTAIN, ## The [Curtain] closes and opens
	MOVE_ONTOP, ## The new screen moves into the space of the old screen, like a card.
	MOVE_ACROSS ## The old screen moves aside for the new screen, like a camera pan
}
@export var transition:Mode = Mode.NONE

enum DIR {DOWN, UP, LEFT, RIGHT}

## The direction of the transition.
## Not all transitions neccesarily have a direction,
#and the precise meaning may vary between implementations
@export var direction:DIR = DIR.UP

## Duration of the transition effect.
## Note that the [enum Transition.CURTAIN] effect plays twice so the overall time will be double
@export_range(0, 5, 0.1) var duration = 0.5

## The direction a screen travels in for [member direction], as a unit vector
## pointing toward the side of the screen it exits by.
## The incoming screen starts at the opposite offset, so it enters from the
## side the outgoing one leaves toward.
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
