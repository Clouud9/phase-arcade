@tool
extends Node3D
class_name CRTScreen

## Texture shown on the screen, fed to the CRT overlay shader as its source
## image. The base material's emission is left untouched.
@export var texture:Texture2D:
	set(tex):
		if not is_node_ready():
			return
		_set_shader_param("image", tex)
		_set_shader_param("effect_strength", 1.0 if tex else 0.0)
	get():
		var mat:ShaderMaterial = $SmArcadeCabAScreen.material_overlay
		if mat:
			return mat.get_shader_parameter("image")
		return null

# ===== CRT Effect Controls =====

# Master effect strength. Blends the CRT effect with the raw image; 0.0 shows
# the unmodified image and bypasses the overlay shader entirely.
@export_range(0.0, 1.0) var effect_strength: float = 1.0:
	set(value):
		effect_strength = value
		_set_shader_param("effect_strength", value)

# Base resolution for pixel-perfect effects (lower values = larger pixels)
@export var resolution: Vector2 = Vector2(320.0, 180.0):
	set(value):
		resolution = value
		_set_shader_param("resolution", value)

# Scanline effect
@export_range(0.0, 1.0) var scan_line_amount: float = 1.0:
	set(value):
		scan_line_amount = value
		_set_shader_param("scan_line_amount", value)

@export_range(-12.0, -1.0) var scan_line_strength: float = -8.0:
	set(value):
		scan_line_strength = value
		_set_shader_param("scan_line_strength", value)

# Screen curvature/warp effect
@export_range(0.0, 5.0) var warp_amount: float = 0.1:
	set(value):
		warp_amount = value
		_set_shader_param("warp_amount", value)

# Visual noise/interference
@export_range(0.0, 0.3) var noise_amount: float = 0.03:
	set(value):
		noise_amount = value
		_set_shader_param("noise_amount", value)

@export_range(0.0, 1.0) var interference_amount: float = 0.2:
	set(value):
		interference_amount = value
		_set_shader_param("interference_amount", value)

# Shadow mask/grille
@export_range(0.0, 1.0) var grille_amount: float = 0.1:
	set(value):
		grille_amount = value
		_set_shader_param("grille_amount", value)

@export_range(1.0, 5.0) var grille_size: float = 1.0:
	set(value):
		grille_size = value
		_set_shader_param("grille_size", value)

# Vignette
@export_range(0.0, 2.0) var vignette_amount: float = 0.6:
	set(value):
		vignette_amount = value
		_set_shader_param("vignette_amount", value)

@export_range(0.0, 1.0) var vignette_intensity: float = 0.4:
	set(value):
		vignette_intensity = value
		_set_shader_param("vignette_intensity", value)

# Chromatic aberration
@export_range(0.0, 1.0) var aberation_amount: float = 0.5:
	set(value):
		aberation_amount = value
		_set_shader_param("aberation_amount", value)

# Rolling line effect
@export_range(0.0, 1.0) var roll_line_amount: float = 0.3:
	set(value):
		roll_line_amount = value
		_set_shader_param("roll_line_amount", value)

@export_range(-8.0, 8.0) var roll_speed: float = 1.0:
	set(value):
		roll_speed = value
		_set_shader_param("roll_speed", value)

# Pixel sharpness/softness
@export_range(-4.0, 0.0) var pixel_strength: float = -2.0:
	set(value):
		pixel_strength = value
		_set_shader_param("pixel_strength", value)


func _ready() -> void:
	# Initialize all shader parameters
	_set_shader_param("image", texture)
	_set_shader_param("effect_strength", effect_strength)
	_set_shader_param("resolution", resolution)
	_set_shader_param("scan_line_amount", scan_line_amount)
	_set_shader_param("scan_line_strength", scan_line_strength)
	_set_shader_param("warp_amount", warp_amount)
	_set_shader_param("noise_amount", noise_amount)
	_set_shader_param("interference_amount", interference_amount)
	_set_shader_param("grille_amount", grille_amount)
	_set_shader_param("grille_size", grille_size)
	_set_shader_param("vignette_amount", vignette_amount)
	_set_shader_param("vignette_intensity", vignette_intensity)
	_set_shader_param("aberation_amount", aberation_amount)
	_set_shader_param("roll_line_amount", roll_line_amount)
	_set_shader_param("roll_speed", roll_speed)
	_set_shader_param("pixel_strength", pixel_strength)


# Helper function to safely set shader parameters on the CRT overlay
func _set_shader_param(param_name: String, value) -> void:
	var mat:ShaderMaterial = $SmArcadeCabAScreen.material_overlay
	if mat:
		mat.set_shader_parameter(param_name, value)
