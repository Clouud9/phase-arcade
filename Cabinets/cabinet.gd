extends Node3D
class_name ArcadeCabinet
## A marvelous device which contians a whole other game

@export var game_name:StringName
## Put your game here
@export var game_scene:PackedScene
## Start powered on, and automatically recieve inputs. Useful for standalone testing.
@export var test_mode = false
## For level design use: If false, will need to be powered on by an external call.
## This is ignored in test mode
@export var start_powered_on:bool
## Subscribe to a named circuit, which controls power state.
## See [HandyLight] for more infos
## This overrides [member start_powered_on]
@export var circuit:StringName
## How often the ScreenLight is updated based on the screen's color.
## Setting this higher will reduce flickering and improve performance,
## but may fail to sell certain dramatic effects.
##
## Increasing the Downsample size will also reduce flickering, but at an exponential cost to performance
@export_range(1, 60, 1, "suffix:frames") var light_update_interval:int = 8

@onready var game_parent = $SubViewport
@onready var screen_mesh_node: MeshInstance3D = %Screen.get_node("SmArcadeCabAScreen")

var curr_game:Node

# --- External Interface ---

func _interacted_by(operator:FirstPersonCharacter):
	operator.set_active_cabinet(self)

func on_operator_release():
	%ScreenInteractZone.active = true
	input_tracker.reset()

func get_observation_delta(from:Camera3D) -> CameraTransform:
	return CameraTransform.new(%ObservationPoint, from)

var discretizer=Discretizer.new()
var input_tracker=InputTracker.new()
func push_input(ev: InputEvent):
	get_viewport().set_input_as_handled()
	if input_tracker._input(ev):
		$SubViewport.push_input(ev)

# --- Lightgun Screen Input ---

## The flattened screen mesh geometry, used to look up the mesh UV at a ray hit
var _screen_verts: PackedVector3Array
var _screen_uvs: PackedVector2Array
var _screen_tris: PackedInt32Array
## Game-screen pixel of the last forwarded press, so the release lands in the same spot
var _screen_pressed_pos := Vector2.INF
## Whether the game viewport's GUI has been told the pointer is inside it

## Remaps a click on the physical screen into the game's own coordinate space and
## pushes it to the game viewport.
##
## Only watchable when no player is operating the cabinet: [member test_mode] uses
## the cabinet's own [code]%ObservationPoint[/code] camera as the pointer.
func _screen_click(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	var game_pos := _game_pos_at_click(event.position)
	if event.pressed:
		if game_pos == Vector2.INF:
			return
		_screen_pressed_pos = game_pos
	else:
		if _screen_pressed_pos == Vector2.INF:
			return
		game_pos = _screen_pressed_pos
		_screen_pressed_pos = Vector2.INF
	get_viewport().set_input_as_handled()
	var local: InputEventMouseButton = event.duplicate() as InputEventMouseButton
	local.position = game_pos
	$SubViewport.push_input(local, true)

## Maps a main-window pixel to game-viewport pixels, or [constant Vector2.INF] when
## the pixel doesn't land on the screen.
func _game_pos_at_click(screen_position: Vector2) -> Vector2:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		cam = %ObservationPoint
	if cam == null:
		return Vector2.INF
	var from := cam.project_ray_origin(screen_position)
	var to := from + cam.project_ray_normal(screen_position) * 10.0
	var params := PhysicsRayQueryParameters3D.create(from, to, Layers.physics3D["Lightgun"])
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return Vector2.INF
	var uv := _screen_uv(hit.position)
	if uv == Vector2.INF:
		return Vector2.INF
	return uv * Vector2($SubViewport.size)

## Barycentrically interpolates the screen mesh UV at [param world_point], assuming
## the point lies on (or very near) the mesh surface.
func _screen_uv(world_point: Vector3) -> Vector2:
	if _screen_tris.is_empty():
		return Vector2.INF
	var local: Vector3 = screen_mesh_node.global_transform.affine_inverse() * world_point
	const EPS := 0.001
	for i in range(0, _screen_tris.size(), 3):
		var a: Vector3 = _screen_verts[_screen_tris[i]]
		var b: Vector3 = _screen_verts[_screen_tris[i + 1]]
		var c: Vector3 = _screen_verts[_screen_tris[i + 2]]
		var bary := Geometry3D.get_triangle_barycentric_coords(local, a, b, c)
		if bary.x >= -EPS and bary.y >= -EPS and bary.z >= -EPS:
			return (
				_screen_uvs[_screen_tris[i]] * bary.x
				+ _screen_uvs[_screen_tris[i + 1]] * bary.y
				+ _screen_uvs[_screen_tris[i + 2]] * bary.z
			)
	return Vector2.INF

func _ensure_screen_geometry() -> void:
	if not _screen_tris.is_empty() or screen_mesh_node == null or screen_mesh_node.mesh == null:
		return
	var arrays := screen_mesh_node.mesh.surface_get_arrays(0)
	_screen_verts = arrays[Mesh.ARRAY_VERTEX]
	_screen_uvs = arrays[Mesh.ARRAY_TEX_UV]
	_screen_tris = arrays[Mesh.ARRAY_INDEX]

var power:bool
func set_power_state(on:bool):
	power = on
	if not is_node_ready():
		await ready
	if on:
		if game_scene:
			curr_game = game_scene.instantiate()
			game_parent.add_child(curr_game)
			print(game_parent)
			print(game_parent.get_children())
		%Screen.texture = $SubViewport.get_texture()
	else:
		%Screen.texture = null
		if curr_game:
			curr_game.queue_free()
	%ScreenInteractZone.active = on

# --- Circuits ---

func _on_circuit_switched(on:bool):
	set_power_state(on)


func join_circuit(s:StringName):
	var switched := HandyLight.register_circuit(s)
	switched.to.connect(_on_circuit_switched)
	if not switched.state and start_powered_on:
		switched.state = start_powered_on
	else:
		set_power_state(switched.state)

# --- Internal Interface ---

## Returns a reference to the nearest [ArcadeCabinet] that [param from] is inside of, or [code]null[/code] if not inside an [ArcadeCabinet]
static func get_cabinet(from:Node) -> ArcadeCabinet:
	while from and from is not ArcadeCabinet:
		from = from.get_parent()
	return from

## Returns the [InputTracker] containing the nearest cabinet's input state.
static func get_input_state(from:Node) -> InputTracker:
	var cab = get_cabinet(from)
	if cab:
		return cab.input_tracker
	return null

func _route_game_audio(node: Node) -> void:
	if not $SubViewport.is_ancestor_of(node):
		return
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).bus = ArcadeCabinetAudio.GAME_BUS
	elif node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).bus = ArcadeCabinetAudio.GAME_BUS

# --- Screen Illumination ---

var downscale_texture:ViewportTexture

var light_from := Color(0, 0, 0, 0)
var light_to := Color(0, 0, 0, 0)
var light_frame := 0
var light_sampled := false

func _sample_screen_light() -> bool:
	var img:Image = downscale_texture.get_image()
	if img == null or img.is_empty():
		return false
	var total := Color(0, 0, 0, 0)
	for y in img.get_height():
		for x in img.get_width():
			total += img.get_pixel(x, y)
	light_from = %ScreenLight.light_color
	light_to = total / (img.get_width() * img.get_height())
	light_frame = 0
	light_sampled = true
	return true

func _update_screen_light() -> void:
	if downscale_texture == null:
		return
	light_frame += 1
	if not light_sampled or light_frame >= light_update_interval:
		_sample_screen_light()
	if not light_sampled:
		return
	if light_update_interval <= 1:
		%ScreenLight.light_color = light_to
		return
	var t := clampf(float(light_frame) / float(light_update_interval - 1), 0.0, 1.0)
	%ScreenLight.light_color = light_from.lerp(light_to, t)

# --- Main ---

func _ready() -> void:
	_ensure_screen_geometry()
	if test_mode:
		set_power_state(true)
	elif circuit != &"":
		join_circuit(circuit)
	else:
		set_power_state(start_powered_on)
	%ScreenInteractZone.interacted_by.connect(_interacted_by)
	for type in [&"AudioStreamPlayer", &"AudioStreamPlayer2D"]:
		for player in $SubViewport.find_children("*", type, true, false):
			_route_game_audio(player)
	get_tree().node_added.connect(_route_game_audio)
	downscale_texture = $Downsample.get_texture()

func _unhandled_input(event: InputEvent) -> void:
	if test_mode:
		if event is InputEventMouseButton:
			_screen_click(event)
		else:
			push_input(event)

func _process(delta:float):
	for ev in discretizer.to_input_events(discretizer.update(input_tracker.movement, delta)):
		$SubViewport.push_input(ev)
	_update_screen_light()
