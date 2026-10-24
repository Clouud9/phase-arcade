extends ScrollContainer

@export var auto_disable = true
@export var autoscroll_enabled = false
@export var scroll_speed = 12.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if autoscroll_enabled:
		var prev_scroll = scroll_vertical
		var scroll_amount = ceil(scroll_speed * delta)
		scroll_vertical += scroll_amount
		if auto_disable and scroll_vertical < (prev_scroll + scroll_amount):
			autoscroll_enabled = false
