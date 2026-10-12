@tool
class_name HandyLight
extends Light3D
## A light with useful features.
##
## Since godot doesn't let us attach multiple scripts to one node, we have to bundle these up together.

# --- Color Temperature ---

const MIN_TEMPERATURE := 1000.0

## Colour temperature in kelvin: 1900 candle, 2700 warm household bulb,
## 6500 midday sun, 10000 overcast sky.
@export_range(1000, 15000, 1, "or_greater", "suffix:K") var temperature := 6500.0:
	set(value):
		temperature = maxf(value, MIN_TEMPERATURE)
		apply_temperature()

## Multiplies the blackbody colour, for coloured bulbs and gels.
@export var tint := Color.WHITE:
	set(value):
		tint = value
		apply_temperature()

func apply_temperature() -> void:
	light_color = color_for_temperature(temperature) * tint

## Blackbody colour for [param kelvin], in the linear space light colours are stored in.
static func color_for_temperature(kelvin: float) -> Color:
	var t := maxf(kelvin, MIN_TEMPERATURE) / 100.0
	var red: float
	var green: float
	var blue: float
	if t <= 66.0:
		red = 255.0
		green = 99.4708025861 * log(t) - 161.1195681661
	else:
		red = 329.698727446 * pow(t - 60.0, -0.1332047592)
		green = 288.1221695283 * pow(t - 60.0, -0.0755148492)
	if t >= 66.0:
		blue = 255.0
	elif t <= 19.0:
		blue = 0.0
	else:
		blue = 138.5177312231 * log(t - 10.0) - 305.0447927307

	var srgb := Color(
		clampf(red, 0.0, 255.0) / 255.0,
		clampf(green, 0.0, 255.0) / 255.0,
		clampf(blue, 0.0, 255.0) / 255.0
	)
	return srgb.srgb_to_linear()

# --- Circuits ---

## Hopefully everything you could possibly need to control your state via the [member circuits] system
class Switched:
	signal on
	signal off
	signal to(bool)
	var state:bool:
		set(b):
			to.emit(b)
			(on if b else off).emit()
			state = b
	func toggle():
		state = not state

static var circuits:Dictionary[StringName, Switched]

## Join an existing circuit, or create a new one if not present
static func register_circuit(s:StringName) -> Switched:
	if not circuits.has(s):
		circuits[s] = Switched.new()
		print("registered circuit: ", s)
	return circuits[s]

## The circuit this [HandyLight] is a part of. Leave empty for no circuit
@export var circuit:StringName = &""

func _on_circuit_switched(state:bool):
	visible = state

func _ready():
	print(self)
	if circuit != &"":
		var switched = register_circuit(circuit)
		switched.to.connect(_on_circuit_switched)
	apply_temperature()
