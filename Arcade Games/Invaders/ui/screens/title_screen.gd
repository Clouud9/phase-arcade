extends ColorRect

func _on_coin_inserted():
	$InsertCoin.pulse_rate = 2

func _ready() -> void:
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		cab.coin_inserted.connect(_on_coin_inserted)
