extends Sprite2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.235, 0.616, 0.745))

func _process(_delta: float) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	position = Vector2(screen_size.x * 0.5, screen_size.y * 0.25)
	scale = Vector2.ONE * (screen_size.y / (3 * texture.get_height()))
