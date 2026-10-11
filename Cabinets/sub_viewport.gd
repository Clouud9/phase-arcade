@tool
extends SubViewport

@export var screen:Node3D
@export_range(0,4,1) var crt_downscale:int=1:
	set(v):
		crt_downscale=v
		if is_node_ready():
			_on_size_changed()

func aspect_normalised(v:Vector2):
	return v/v.y

const screen_intrinsic_aspect_ratio = 4.0/3.0
func screen_aspect_ratio(n:Node3D):
	return n.scale.x/n.scale.y * screen_intrinsic_aspect_ratio

func _on_size_changed():
	if screen:
		var aspect_ratio = float(size.x)/float(size.y)
		var aspect_ratio_differnece = screen_aspect_ratio(screen) / aspect_ratio
		screen.scale.x /= aspect_ratio_differnece
		screen.resolution = size / crt_downscale

func _ready() -> void:
	size_changed.connect(_on_size_changed)
