@tool
extends CollisionShape2D
class_name AutoRectangleCollider2D

@export var sprite: Sprite2D

var _sprite: Sprite2D:
	set(val):
		if _sprite:
			disconnect_sprite()
		_sprite = val
		connect_sprite()
		set_region()

func connect_sprite():
	if not _sprite.frame_changed.is_connected(set_region):
		_sprite.frame_changed.connect(set_region)
	if not _sprite.texture_changed.is_connected(set_region):
		_sprite.texture_changed.connect(set_region)

func disconnect_sprite():
	if _sprite.frame_changed.is_connected(set_region):
		_sprite.frame_changed.disconnect(set_region)
	if _sprite.texture_changed.is_connected(set_region):
		_sprite.texture_changed.disconnect(set_region)

func set_region():
	if not (shape is RectangleShape2D):
		shape = RectangleShape2D.new()
	var r = _sprite.get_rect()
	shape.size = r.size

func auto_set_sprite():
	for n in get_parent().get_children():
		if n is Sprite2D:
			_sprite = n

func _ready():
	if sprite:
		_sprite = sprite
	else:
		auto_set_sprite()
