extends Button

func _ready() -> void:
	if OS.get_name() == "Web":
		queue_free()

func _pressed() -> void:
	get_tree().quit()
