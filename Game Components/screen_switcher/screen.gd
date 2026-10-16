extends Control
class_name Screen

## The transition played when this screen is shown, and reversed when it is
## hidden.
@export var transition:Transition
## Keep the screen processing (and receiving input) even while it is hidden.
## When unset, a hidden screen is switched to [constant Node.PROCESS_MODE_DISABLED].
@export var active_while_not_shown = false

## If true, this screen's transition must be played in reverse before the next screen can be shown.
## If false, the next screen will be played regardless of what's going on with this screen. Even if it's currently in the middle of animating
@export var require_reversal:bool = false

## Progress of the currently playing transition, from 0.0 to 1.0, fully out to
## fully in. This may not be time-uniform if a non-linear blending function is
## used.
var progress:float

# Elapsed time through the transition, in seconds; progress is this shaped by
# the transition's duration and blending function.
var _time:float

## Advances the transition by [param delta] seconds and returns the new
## [member progress]. Progress reaches 1.0 once the transition's duration has
## elapsed, then holds there.
## [param delta] can be negative to reverse the transition
func update_progress(delta:float) -> float:
	if transition.is_instant():
		_time = 1.0 if delta >= 0.0 else 0.0
	else:
		_time = clampf(_time + delta, 0.0, transition.duration)
	progress = transition.calculate_progress(_time)
	return progress

## Jumps straight to the resting state, fully shown or fully hidden, without
## animating. Used to establish initial state and to snap non-animated changes.
func snap(shown:bool) -> void:
	if transition and not transition.is_instant():
		_time = transition.duration if shown else 0.0
		progress = transition.calculate_progress(_time)
	else:
		_time = 0.0
		progress = 1.0 if shown else 0.0
	set_shown(shown)

## A hidden screen is disabled unless [member active_while_not_shown] is set.
func set_shown(shown: bool) -> void:
	visible = shown
	if shown or active_while_not_shown:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		process_mode = Node.PROCESS_MODE_DISABLED

func _ready():
	if not transition:
		transition = Transition.new()
	set_anchors_preset(PRESET_FULL_RECT)
	set_shown(visible)
