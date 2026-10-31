extends Button

func _ready() -> void:
	# Quitting from a cabinet would close the whole arcade
	if OS.get_name() == "Web" or ArcadeCabinet.get_cabinet(self) != null:
		queue_free()

func _pressed() -> void:
	get_tree().quit()
