@tool
extends Control
class_name Screen

## The transition played when this screen is shown, and reversed when it is hidden.
@export var transition:Transition
## Keep the screen processing (and receiving input) even while it is hidden.
## When unset, a hidden screen is switched to [constant Node.PROCESS_MODE_DISABLED].
@export var active_while_not_shown = false
## If true, this screen's transition must be played in reverse before the next screen can be shown.
## If false, the next screen will be played regardless of what's going on with this screen. Even if it's currently in the middle of animating
@export var require_reversal:bool = false

func is_shown():
	return visible and (process_mode == Node.PROCESS_MODE_INHERIT or active_while_not_shown)

### Sets the screen visibility, and the other things that are triggered by visibility
### Called on transition, not every frame
func _set_shown(shown:bool):
	visible = shown
	var pause = shown or active_while_not_shown
	process_mode = Node.PROCESS_MODE_INHERIT if pause else Node.PROCESS_MODE_DISABLED

signal done

## Renders the screen at [param progress]: [code]1.0[/code] at rest, [code]0.0[/code]
## fully off-screen, leaving toward [param exit]. Intended for use by [ScreenSwicther]
func _set_state(progress: float, exit: Vector2) -> void:
	var shifted := progress < 1.0
	offset_transform_enabled = shifted
	if shifted:
		offset_transform_position_ratio = exit * (1.0 - progress)

	var should_show = progress > 0.0
	if should_show != is_shown():
		_set_shown(should_show)

func _ready():
	if not transition:
		transition = Transition.new()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)

static func get_screen(from: Node) -> Screen:
	while from and from is not Screen:
		from = from.get_parent()
	return from
