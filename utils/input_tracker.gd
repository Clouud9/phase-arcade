extends Object
class_name InputTracker
## Reconstructs input state from events
## Used as an alternative to [Input] if global input querying is undesirable

var movement: Vector2
var firing: bool
var bombing: bool
var cursor_pos: Vector2

var _input_left: float
var _input_right: float
var _input_up: float
var _input_down: float

## Reset inputs that are not currently pressed.
##
## Can be useful for flushing stuck inputs but will cause problems if used unconditionally
func sanity_check():
	if not Input.is_action_pressed("left"):
		_input_left = 0.0
	if not Input.is_action_pressed("right"):
		_input_right = 0.0
	if not Input.is_action_pressed("up"):
		_input_up = 0.0
	if not Input.is_action_pressed("down"):
		_input_down = 0.0

	if not Input.is_action_pressed("fire"):
		firing = false

## Feed an event to update the state
func _input(ev: InputEvent) -> bool:
	var tracked=false
	if ev.is_echo():
		return false
	# NOTE: the lack of `elif` here is actually important for controllers
	# It seems JoyPadMotions is all four always
	if ev.is_action("left"):
		tracked=true
		_input_left = ev.get_action_strength("left")
	if ev.is_action("right"):
		tracked=true
		_input_right = ev.get_action_strength("right")
	if ev.is_action("up"):
		tracked=true
		_input_up = ev.get_action_strength("up")
	if ev.is_action("down"):
		tracked=true
		_input_down = ev.get_action_strength("down")
	movement = Vector2(_input_right - _input_left, _input_down - _input_up).limit_length(1)

	if ev.is_action("fire"):
		firing = not ev.is_action_released("fire")
	elif ev.is_action("bomb"):
		bombing = not ev.is_action_released("bomb")
	else:
		return tracked
	return true

## Sets all tracked inputs to their zero state
func reset():
	movement = Vector2.ZERO
	firing = false
	bombing = false
	cursor_pos = Vector2.ZERO
	_input_left=0
	_input_right=0
	_input_up=0
	_input_down=0
