extends Object
class_name Discretizer
## Designed to solve the age-old problem of controlling ui with a joystick in Godot.
## I'm sure there's a simpler way to do it, but I didn't find it.
## Update it every from with the joystick position, and it will spit out discrete directions units,
## Which can be translated to [InputEvent]s if you're extra lazy

var repeat_delay:float
var repeat_interval:float
var deadzone:float

var _direction:Vector2i = Vector2i.ZERO
var _hold_time:float = 0.0
var _emitted:int = 0

func _init(repeat_delay:float=0.5, repeat_interval:float=0.2, deadzone:float=0.2):
	self.repeat_delay=repeat_delay
	self.repeat_interval=repeat_interval
	self.deadzone=deadzone

func update(v:Vector2, delta_t:float) -> Vector2i:
	var dir := _quantize(v)
	if dir == Vector2i.ZERO:
		_direction = Vector2i.ZERO
		_hold_time = 0.0
		_emitted = 0
		return Vector2i.ZERO
	if dir != _direction:
		_direction = dir
		_hold_time = 0.0
		_emitted = 1
		return dir
	_hold_time += delta_t
	var total := 1
	var delay := maxf(repeat_delay, 0.0)
	if repeat_interval > 0.0 and _hold_time >= delay:
		var repeats := int((_hold_time - delay) / repeat_interval)
		total = 2 + repeats - (1 if delay <= 0.0 else 0)
	var steps := maxi(total - _emitted, 0)
	_emitted = total
	return _direction * steps

func to_input_events(dir:Vector2i) -> Array[InputEvent]:
	var events:Array[InputEvent] = []
	for i in maxi(dir.x, 0):
		events.append(_key_event(KEY_RIGHT))
	for i in maxi(-dir.x, 0):
		events.append(_key_event(KEY_LEFT))
	for i in maxi(dir.y, 0):
		events.append(_key_event(KEY_DOWN))
	for i in maxi(-dir.y, 0):
		events.append(_key_event(KEY_UP))
	return events

func _key_event(key:Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	return ev

func _quantize(v:Vector2) -> Vector2i:
	if v.length() < deadzone:
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(1 if v.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if v.y > 0.0 else -1)
