extends DialogueScreen

func _ready() -> void:
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		await cab.pop_coin()
		confirm()
