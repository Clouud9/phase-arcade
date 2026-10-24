@tool
extends Node3D
class_name ArcadeCabinet
## A marvelous device which contains a whole other game

## Applies a material to the cabinet body and controls and anything else with the default material
@export var custom_material:BaseMaterial3D:
	set(value):
		custom_material = value
		if is_node_ready():
			set_cabinet_material(self, value)

## Put your game here
@export var game_scene:PackedScene
## Start powered on, and automatically receive inputs. Useful for standalone testing.
@export var test_mode = false
## For level design use: If false, will need to be powered on by an external call.
## This is ignored in test mode
@export var start_powered_on:bool
## Subscribe to a named circuit, which controls power state.
## See [HandyLight] for more information
## This overrides [member start_powered_on]
@export var circuit:StringName
## How often the ScreenLight is updated based on the screen's color.
## Setting this higher will reduce flickering but may fail to sell certain dramatic effects.
## Note that although a higher value can improve performance, If updating the light every frame causes lag,
## updating the light every n frames will still cause lag every n frames. So it's not a real solution
## Increasing the Downsample size will also reduce flickering, but at an exponential cost to performance
@export_range(1, 60, 1, "suffix:frames") var light_update_interval:int = 8

@onready var game_parent = $SubViewport
@onready var speaker: ArcadeCabinetAudio = $Speaker

var curr_game:Node

# --- External Interface ---

func _interacted_by(operator:FirstPersonCharacter):
	operator.set_active_cabinet(self)

## Called when the player stops playing the cabinet
func on_operator_release():
	%ScreenInteractZone.active = true
	input_tracker.reset()
	_center_cursor()

func get_observation_delta(from:Camera3D) -> CameraTransform:
	return CameraTransform.new(%ObservationPoint, from)

var discretizer=Discretizer.new()
var input_tracker=InputTracker.new()
func push_input(ev: InputEvent):
	get_viewport().set_input_as_handled()
	if input_tracker._input(ev):
		$SubViewport.push_input(ev)

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


signal coin_inserted

## Number of unprocessed coins in the machine.
## A coin is "processed" when the game calls [method pop_coin]
## and converts it into a life or a retry or whatever
var coins:int = 0
func _on_insert_coin():
	coins += 1
	coin_inserted.emit()

## Waits for [prop coins] to be above zero decrements then it
## Use with [code]await[/code]
func pop_coin():
	while coins < 1:
		await coin_inserted
	coins -= 1

# --- Screen Illumination ---

## A low-res copy of the screen texture used for lighting calculation and similar
## The specific resolution will vary depending on the needs of the game
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

# --- Lightgun Screen Input ---

var _screen_pressed_pos := Vector2.INF

## World-space point on the screen the operator is currently aiming at. Mirrors
## [member InputTracker.cursor_pos], which holds the same point in game-viewport
## pixels. Keeps its last on-screen value while the lightgun is aimed off-screen.
var cursor_pos := Vector3.ZERO

func _center_cursor() -> void:
	input_tracker.cursor_pos = Vector2($SubViewport.size) / 2.0
	var mesh_node: MeshInstance3D = %Screen.get_node_or_null("SmArcadeCabAScreen")
	if mesh_node:
		cursor_pos = mesh_node.global_transform * mesh_node.get_aabb().get_center()

func _screen_click(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if not _update_cursor(event.position):
			return
		_screen_pressed_pos = input_tracker.cursor_pos
	elif _screen_pressed_pos == Vector2.INF:
		return
	get_viewport().set_input_as_handled()
	var local: InputEventMouseButton = event.duplicate() as InputEventMouseButton
	local.position = _screen_pressed_pos
	$ControlPlane.handle_event(event)
	$SubViewport.push_input(local, true)
	if not $SubViewport.is_input_handled():
		_forward_3d_input(local, _screen_pressed_pos)
	if not event.pressed:
		_screen_pressed_pos = Vector2.INF

# Delivers a mouse event to the [CollisionObject3D] input system of the game
# running inside the [SubViewport], so [code]_input_event[/code] fires for
# bodies with [member CollisionObject3D.input_ray_pickable] set.
#
# The engine's own viewport picking can't reach the game: the [SubViewport] is
# drawn onto a curved mesh rather than hosted in a [SubViewportContainer], its
# mouse never enters the viewport, and the operating camera keeps the mouse
# captured. So the ray is cast here and the event dispatched by hand, mirroring
# [code]Viewport::_collision_object_3d_input_event[/code].
#
# [param position] is in game-viewport pixels, matching
# [member InputTracker.cursor_pos].
func _forward_3d_input(event: InputEventMouse, position: Vector2) -> void:
	var cam: Camera3D = $SubViewport.get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(position)
	var to := from + cam.project_ray_normal(position) * cam.far
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	var hit: Dictionary = $SubViewport.find_world_3d().direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return
	var collider := hit["collider"] as CollisionObject3D
	if collider == null or not collider.input_ray_pickable:
		return
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	var shape: int = hit["shape"]
	if collider.has_method(&"_input_event"):
		collider._input_event(cam, event, point, normal, shape)
	collider.emit_signal(&"input_event", cam, event, point, normal, shape)

# Raycasts a main-window pixel against the screen and returns the intersection,
# or an empty dictionary when the pixel doesn't land on the screen.
func _screen_hit(screen_position: Vector2) -> Dictionary:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		cam = %ObservationPoint
	if cam == null:
		return {}
	var from := cam.project_ray_origin(screen_position)
	var to := from + cam.project_ray_normal(screen_position) * 10.0
	var params := PhysicsRayQueryParameters3D.create(from, to, Layers.physics3D["Lightgun"])
	return get_world_3d().direct_space_state.intersect_ray(params)

# Updates [member cursor_pos] and [member InputTracker.cursor_pos] from a
# main-window pixel, returning whether the pixel landed on the screen. The cursors
# keep their last on-screen position when the pixel misses.
func _update_cursor(screen_position: Vector2) -> bool:
	var hit := _screen_hit(screen_position)
	var uv := RaySensor.uv_from_hit(hit) if not hit.is_empty() else Vector2.INF
	if uv == Vector2.INF:
		return false
	cursor_pos = hit["position"]
	input_tracker.cursor_pos = uv * Vector2($SubViewport.size)
	return true

# --- Material ---

const BODY_META:StringName = &"_arcade_cabinet_body"
const DEFAULT_BODY_MATERIAL:Material = preload("res://Cabinets/Arcade_machine.tres")
const OVERRIDE_META:StringName = &"_arcade_body_surfaces"

## Returns whether [param mat] is used by the cabinet's body.
static func is_body_material(mat:Material) -> bool:
	if mat == null:
		return false
	return mat == DEFAULT_BODY_MATERIAL or mat.has_meta(BODY_META)

## Applies [param mat] to every body surface under [param root].
##
## Surfaces are found by material, so parts of the cabinet with their own
## material, like the screen or the coin panel, are left alone. The material is
## set as a per-surface override on the [MeshInstance3D], which leaves the
## model's own material in place, so this can be repeated any number of times.
##
## Pass [code]null[/code] to restore the model's material.
##
## Returns the number of surfaces which were changed.
static func set_cabinet_material(root:Node, mat:BaseMaterial3D) -> int:
	if root == null:
		return 0
	return _apply_body_material(root, mat)

static func _apply_body_material(node:Node, mat:BaseMaterial3D) -> int:
	var count := 0
	if node is MeshInstance3D:
		count += _apply_to_body_mesh(node as MeshInstance3D, mat)
	if node is Viewport:
		return count # a separate 3D world; the game lives in there
	for child in node.get_children():
		count += _apply_body_material(child, mat)
	return count

static func _apply_to_body_mesh(mi:MeshInstance3D, mat:BaseMaterial3D) -> int:
	var mesh := mi.mesh
	if mesh == null or mi.material_override != null:
		return 0 # a material set in the editor wins over ours
	var owned:Array = mi.get_meta(OVERRIDE_META, [])
	var still_owned:Array = []
	var count := 0
	for i in mesh.get_surface_count():
		if not is_body_material(mesh.surface_get_material(i)):
			if owned.has(i):
				mi.set_surface_override_material(i, null) # no longer body: undo
				count += 1
			continue
		if mi.get_surface_override_material(i) != null and not owned.has(i):
			continue # an override made by hand, leave it alone
		mi.set_surface_override_material(i, mat)
		still_owned.append(i)
		count += 1
	if still_owned.is_empty():
		mi.remove_meta(OVERRIDE_META)
	else:
		mi.set_meta(OVERRIDE_META, still_owned)
	return count

# --- Audio ---

func _route_game_audio(node: Node) -> void:
	if speaker.bus_name == &"" or not $SubViewport.is_ancestor_of(node):
		return
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).bus = speaker.bus_name
	elif node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).bus = speaker.bus_name
	elif node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).bus = speaker.bus_name


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

var power:bool
func set_power_state(on:bool):
	power = on
	if not is_node_ready():
		await ready
	if on:
		if game_scene:
			curr_game = game_scene.instantiate()
			game_parent.add_child(curr_game)
		%Screen.texture = $SubViewport.get_texture()
	else:
		%Screen.texture = null
		if curr_game:
			curr_game.queue_free()
	%ScreenInteractZone.active = on

# --- Main ---

func _ready() -> void:
	set_cabinet_material(self, custom_material)
	if Engine.is_editor_hint():
		return
	get_tree().node_added.connect(_route_game_audio)
	if test_mode:
		set_power_state(true)
	elif circuit != &"":
		join_circuit(circuit)
	else:
		set_power_state(start_powered_on)
	%ScreenInteractZone.interacted_by.connect(_interacted_by)
	for type in [&"AudioStreamPlayer", &"AudioStreamPlayer2D", &"AudioStreamPlayer3D"]:
		for player in $SubViewport.find_children("*", type, true, false):
			_route_game_audio(player)
	downscale_texture = $Downsample.get_texture()
	_center_cursor()

func _unhandled_input(event: InputEvent) -> void:
	if test_mode:
		if event.is_action_pressed("insert_coin"):
			_on_insert_coin()
		elif event is InputEventMouseButton:
			_screen_click(event)
		elif event is InputEventMouseMotion:
			_update_cursor(event.position)
		else:
			push_input(event)

func _process(delta:float):
	if Engine.is_editor_hint():
		return
	for ev in discretizer.to_input_events(discretizer.update(input_tracker.movement, delta)):
		$SubViewport.push_input(ev)
	_update_screen_light()
