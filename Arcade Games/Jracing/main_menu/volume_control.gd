extends HSlider

@onready var bus := AudioServer.get_bus_index(name)

func _ready() -> void:
	if AudioServer.is_bus_mute(bus):
		value = 0
	else:
		value = clampf(AudioServer.get_bus_volume_linear(bus), 0, 1)

func _value_changed(new_value: float) -> void:
	if new_value == 0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_volume_linear(bus, new_value)
		AudioServer.set_bus_mute(bus, false)
