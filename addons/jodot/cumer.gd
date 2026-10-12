extends Object
class_name Cumer

var f: Callable
var t: float
var i: int
var accum: float

func tally():
	i+= 1

func _init(rate: float, callback: Callable = tally):
	assert(rate > 0)
	t = 1.0/rate
	f = callback

func reset():
	accum = 0

func add(delta: float):
	accum += delta
	while accum > t:
		accum -= t
		f.call()

func cycles_accumulated() -> int:
	var _i = i
	i = 0
	return _i
