@tool
extends Label
class_name InsertCoinLabel

@export_range(0, 2, 0.1) var pulse_rate:float = 1.1
@export_range(0, 1, 0.1) var pulse_width:float = 0.6

var pulse_accum:float = 0
func _process(delta: float) -> void:
	if get_parent() and not get_parent().is_visible_in_tree():
		return
	if pulse_rate > 0:
		var pulse_duration = 1.0/pulse_rate
		pulse_accum += delta
		if pulse_accum > pulse_duration:
			pulse_accum = 0
			visible = true
		elif pulse_accum > pulse_duration * pulse_width:
			visible = false
	else:
		visible = true
	text = "Insert Coin"

func _on_insert_coin():
	pulse_rate += 5
	await Utils.delay(1)
	pulse_rate -= 5

func _ready() -> void:
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		cab.coin_inserted.connect(_on_insert_coin)
