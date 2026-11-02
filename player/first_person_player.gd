@tool
class_name FirstPersonCharacter
extends CharacterBody3D

const speed = 3.0
const accel = 20.0

@export_range(0.2, 2.0, 0.01) var mouse_sensitivity:float = 1
@export_range(0.2, 2.0, 0.01) var controller_sensitivity:float = 1

@export var height = 1.2:
	set(val):
		height = max(val, width)
		setup_children()
@export var width = 0.5:
	set(val):
		width = val
		if height < val:
			height = val
		else:
			setup_children()

# --- Crouching ---

func set_body_to_head():
	var head_col:SphereShape3D = $Head/CollisionShape3D.shape
	var body_col:CapsuleShape3D = $CollisionShape3D.shape
	body_col.radius = head_col.radius
	body_col.height = $Head.position.y + head_col.radius
	$CollisionShape3D.position.y = body_col.height / 2

func setup_children() -> void:
	if not is_node_ready():
		# the above setters will trigger this early, so we have to wait until our children come home
		await ready
	assert (height >= width) #TODO: assert does nothing in tool mode, need a better way to handle this

	collision_layer = Layers.physics3D["Player"]
	collision_mask = Layers.physics3D["Solid"]
	$Head.collision_layer = collision_layer
	$Head.collision_mask = collision_mask

	var head_col:SphereShape3D = $Head/CollisionShape3D.shape
	head_col.radius = width/2
	$Head.position.y = height - head_col.radius

	set_body_to_head()

	%InteractRay.collision_mask = Layers.physics3D["Interactive"]

func change_height(new_height:float) -> KinematicCollision3D:
	var delta = Vector3(0, new_height - $Head.position.y, 0)
	var result = $Head.move_and_collide(delta)
	set_body_to_head()
	return result

# --- Interaction ---

func _interact() -> bool:
	var target = %InteractRay.get_collider()
	if target and target.has_method("interact"):
		target.interact(self)
		return true
	return false

class Inventory extends Resource:
	@export var contents:Dictionary[StringName, Array] #Array[Node]
	func collect(n:Node, type:StringName):
		if not contents.has(type):
			contents[type] = [n]
		else:
			contents[type].append(n)
		n.get_parent().remove_child(n)
		print(contents)

var inventory = Inventory.new()

# --- Arcade Cabinets ---

var active_cabinet:ArcadeCabinet = null
var active_camera_transform:CameraTransform = null
var camera_transform_factor:float

func set_active_cabinet(cab:ArcadeCabinet):
	active_cabinet = cab
	active_camera_transform = cab.get_observation_delta(%Camera)
	camera_transform_factor = 0

func clear_active_cabinet():
	if not active_cabinet:
		return
	active_cabinet.on_operator_release()
	active_cabinet = null

const UNLOCK_ANGLE := 50.0
## 1: fully locked-in, 0: fully daydreaming
func _cabinet_lock_factor() -> float:
	return 1.0 - pow(active_camera_transform.angle_from(
		base_camera_transform.transform.basis
	) / UNLOCK_ANGLE, 2) #squaring smoothes it out a bit; looks nicer

# --- Main ---

func handle_collision(k: KinematicCollision3D):
	var col = k.get_collider()
	if col is RigidBody3D:
		col.apply_force(
			col.to_local(k.get_remainder() * -1000),
			col.to_local(k.get_position())
		)

var base_camera_transform:CameraTransform
func _ready():
	setup_children()
	base_camera_transform = CameraTransform.new(%Camera)

const CAM_T_RATE:float = 3.0
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	look(Vector2(
		Input.get_axis("look_right", "look_left"),
		Input.get_axis("look_down", "look_up")
	) * controller_sensitivity / 30)

	base_camera_transform.position = $Head.global_position
	if active_camera_transform:
		camera_transform_factor = min(camera_transform_factor + CAM_T_RATE * (delta if active_cabinet else -delta), 1)
		camera_transform_factor = minf(camera_transform_factor, _cabinet_lock_factor())
		var factor := smoothstep(0.0, 1.0, camera_transform_factor)
		base_camera_transform.blend_relative(
			active_camera_transform,
			%Camera,
			factor
		)
		if active_cabinet and factor <= 0.0:
			camera_transform_factor = 0
			clear_active_cabinet()
		elif not active_cabinet and camera_transform_factor <= 0.0:
			active_camera_transform = null
	else:
		base_camera_transform.apply_absolute(%Camera)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var crouching = Input.is_action_pressed("crouch")
	const crouch_speed:float = 10
	var target_height = height * (0.4 if crouching else 1.0)
	change_height(lerpf($Head.position.y, target_height, 1.0 - exp(-crouch_speed * delta)))

	var walk_input:Vector2
	if active_cabinet == null:
		walk_input = Input.get_vector("left", "right", "up", "down").limit_length(1)
	else:
		walk_input = Vector2.ZERO
	var walk = walk_input.rotated(-%Camera.global_rotation.y) * speed * clampf($Head.position.y / height, 0.0, 1.0)

	# maybe this should be relative to the floor normal, but probably doesn't matter
	velocity.x = move_toward(velocity.x, walk.x, accel * delta)
	velocity.z = move_toward(velocity.z, walk.y, accel * delta)

	var target =  %InteractRay.get_collider()
	if target:
		target.hover(self)

	move_and_slide()
	for i in get_slide_collision_count():
		handle_collision(get_slide_collision(i))

func look(relative:Vector2):
	var t = %Camera.transform.basis
		# soft clamp pitch using magic numbers from the matrix
	if sign(relative.y) != sign(t.z.y):
		relative.y *= t.y.y
	base_camera_transform.yaw_and_pitch(relative)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var _look = ev.relative * -mouse_sensitivity / 1000
		if DisplayServer.get_name() == &"web":
			_look *=  0.6 # Look is faster on the web for some reason
		look(_look)
	if ev.is_action_pressed("lights"):
		HandyLight.circuits["lobby"].toggle()
	if ev.is_action_pressed("interact"):
		if _interact():
			get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif active_cabinet != null:
		active_cabinet.push_input(ev)
