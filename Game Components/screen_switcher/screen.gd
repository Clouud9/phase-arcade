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

# Raw time through the transition; progress is this shaped by the blending function.
var _time:float

## Advances the transition by [param delta] seconds and returns the new
## [member progress]. Progress reaches 1.0 once the transition's duration has
## elapsed, then holds there.
## [param delta] can be negative to reverse the transition
func update_progress(delta:float) -> float:
	assert(transition.duration > 0) #TODO handle this case elsewhere
	_time = clampf(_time + delta / transition.duration, 0.0, 1.0)
	match transition.blending_function:
		Transition.BLEND_FUNC.SMOOTH:
			progress = smoothstep(0.0, 1.0, _time)
		_:
			progress = _time
	return progress

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
