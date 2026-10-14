extends Control
class_name Screen

@export var transition:Transition
## sets the screen's [member process_mode]
@export var active_while_not_shown = false

func _ready():
	set_anchors_preset(PRESET_FULL_RECT)
