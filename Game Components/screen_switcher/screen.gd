extends Control
class_name Screen

@export var transition:Transition
## Keep the screen processing (and receiving input) even while it is hidden.
## When unset, a hidden screen is switched to [constant Node.PROCESS_MODE_DISABLED].
@export var active_while_not_shown = false

func _ready():
	set_anchors_preset(PRESET_FULL_RECT)
	set_shown(visible)

## Show or hide the screen, keeping [member process_mode] in sync.
## A hidden screen is disabled unless [member active_while_not_shown] is set.
func set_shown(shown: bool) -> void:
	visible = shown
	if shown or active_while_not_shown:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
