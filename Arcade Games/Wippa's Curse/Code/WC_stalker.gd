extends CharacterBody3D

@export var player_path: NodePath 
@export var stalking_speed: float = 1.3
@export var hunting_speed: float = 3.5
@export var cross_dash_speed: float = 7.0
@export var flee_speed: float = 7.5 
@export var stalk_distance: float = 9.0 
@export var lunge_trigger_distance: float = 3.8
@export var lunge_cooldown: float = 5.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $"pippa-enemy-animated-model/movement/AnimationTree"

# CACHE PLAYBACK CONTROL
var anim_playback: AnimationNodeStateMachinePlayback = null
@onready var character_model: Node3D = $"pippa-enemy-animated-model"

# --- FIXED 2D AUDIO REFERENCE ---
# Ensure your node name inside Pippa's scene tree is exactly "StalkAudio2D" 
# and its type is a standard, un-numbered AudioStreamPlayer!
@onready var stalk_audio_2d: AudioStreamPlayer = $StalkAudio2D

# Finite State Machine Enums
enum State { STALKING, CROSS_DASHING, LUNGING, FLEEING, COOLDOWN }
var current_state: State = State.STALKING

var player: Node3D = null
var player_camera: Camera3D = null 
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Systems Tracking variables
var target_refresh_timer: float = 0.0
var behavior_timer: float = 0.0
var cross_dash_target: Vector3 = Vector3.ZERO
var flee_target_position: Vector3 = Vector3.ZERO
var lunge_target_position: Vector3 = Vector3.ZERO
var can_lunge: bool = true

func _ready() -> void:
	if player_path:
		player = get_node(player_path) as Node3D
		find_player_camera(player)
	
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	platform_floor_layers = 0 
	nav_agent.avoidance_enabled = false 
	
	if animation_tree:
		animation_tree.active = true
		anim_playback = animation_tree.get("parameters/playback")
		
	await get_tree().physics_frame
	
	# Start her 2D track loop natively (Bypasses all 3D mesh culling)
	if stalk_audio_2d:
		if not stalk_audio_2d.playing:
			stalk_audio_2d.play()
		modulate_audio()

	# --- FIXED: SELF-CONNECT HITBOX SIGNAL IN CASE IT CAME UNLINKED ---
	if has_node("HitBox"):
		var hitbox_node = $HitBox
		hitbox_node.body_entered.connect(func(body: Node3D):
			if body.has_method("get_knocked_down"):
				body.get_knocked_down()
		)

func modulate_audio():
	# --- FIXED GODOT 4 PROXIMITY VOLUME ENGINE ---
	if stalk_audio_2d and stalk_audio_2d.playing:
		var distance_to_player = global_position.distance_to(player.global_position)
		var hearing_range: float = 20.0
		
		if distance_to_player > hearing_range:
			stalk_audio_2d.volume_db = -60.0 # Absolute silence
		else:
			var proximity_pct = 1.0 - (distance_to_player / hearing_range)
			# Standard AudioStreamPlayer volume mapping (Bypasses buggy panning completely)
			stalk_audio_2d.volume_db = lerp(-20.0, 12.0, proximity_pct) 

func _physics_process(delta: float) -> void:
	# Continuous stable floor pinning gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -1.0 

	if not player:
		safely_travel_to("pippa-enemy-animated_Idle")
		move_and_slide()
		return

	modulate_audio()

	# State Evaluation Engine Loop
	match current_state:
		State.STALKING:
			handle_stalking_state(delta)
		State.CROSS_DASHING:
			handle_cross_dashing_state(delta)
		State.LUNGING:
			handle_lunging_state(delta)
		State.FLEEING:
			handle_fleeing_state(delta)
		State.COOLDOWN:
			handle_cooldown_state(delta)

# --- STATE CONTROLLERS ---

func handle_stalking_state(delta: float) -> void:
	target_refresh_timer += delta
	if target_refresh_timer >= 0.1:
		nav_agent.target_position = player.global_position
		target_refresh_timer = 0.0

	var distance: float = global_position.distance_to(player.global_position)
	
	if is_player_looking_directly_at_me() and distance < stalk_distance:
		trigger_flee_sequence()
		return

	behavior_timer += delta
	if behavior_timer >= 1.0:
		behavior_timer = 0.0
		if randf() < 0.20 and distance < stalk_distance and distance > lunge_trigger_distance:
			setup_cross_dash()
			return

	if distance <= lunge_trigger_distance and can_lunge:
		if is_player_looking_at_me():
			start_lunge_sequence()
			return

	navigate_toward_point(nav_agent.get_next_path_position(), stalking_speed, delta)

func handle_fleeing_state(delta: float) -> void:
	target_refresh_timer += delta
	if target_refresh_timer >= 0.1:
		nav_agent.target_position = flee_target_position
		target_refresh_timer = 0.0

	var distance_to_hiding_spot: float = global_position.distance_to(flee_target_position)
	
	if distance_to_hiding_spot <= 1.0 or nav_agent.is_navigation_finished() or (is_on_wall() and velocity.length() < 0.5):
		current_state = State.STALKING
		behavior_timer = 0.0
		return
		
	navigate_toward_point(nav_agent.get_next_path_position(), flee_speed, delta)

func handle_cross_dashing_state(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	var target_pos = Vector3(cross_dash_target.x, global_position.y, cross_dash_target.z)
	global_position = global_position.move_toward(target_pos, cross_dash_speed * delta)
	
	safely_travel_to("pippa-enemy-animated_Run") 
	smooth_look_at(cross_dash_target, delta)
	
	# --- FIXED: RE-INJECT PHYSICS CALCULATIONS IN SPECIAL STATES ---
	move_and_slide()
	
	if global_position.distance_to(target_pos) <= 0.4 or is_on_wall():
		current_state = State.STALKING
		behavior_timer = 0.0

func handle_lunging_state(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	if is_on_wall():
		stop_lunge_instantly()
		return

	var target_pos = Vector3(lunge_target_position.x, global_position.y, lunge_target_position.z)
	global_position = global_position.move_toward(target_pos, 6.0 * delta)
	
	# --- FIXED: MUST CALL MOVE_AND_SLIDE TO TRIGGER JUMPSCARE OVERLAP SENSORS ---
	move_and_slide()

func handle_cooldown_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 15.0 * delta)
	velocity.z = move_toward(velocity.z, 0, 15.0 * delta)
	safely_travel_to("pippa-enemy-animated_Idle")
	move_and_slide()

# --- HELPER PROCEDURES ---

func navigate_toward_point(target_point: Vector3, speed: float, delta: float) -> void:
	var direction: Vector3 = global_position.direction_to(target_point)
	direction.y = 0
	direction = direction.normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		smooth_look_at(global_position + direction, delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	if velocity.length() > 0.1:
		safely_travel_to("pippa-enemy-animated_Run")
	else:
		safely_travel_to("pippa-enemy-animated_Idle")

func smooth_look_at(target_point: Vector3, delta: float) -> void:
	var look_target = Vector3(target_point.x, global_position.y, target_point.z)
	if not global_position.is_equal_approx(look_target):
		var target_transform = global_transform.looking_at(look_target, Vector3.UP)
		target_transform = target_transform.rotated_local(Vector3.UP, PI)
		var blend_weight = clamp(6.0 * delta, 0.0, 1.0)
		global_transform = global_transform.interpolate_with(target_transform, blend_weight)

func find_player_camera(node: Node) -> void:
	if node is Camera3D:
		player_camera = node
		return
	for child in node.get_children():
		find_player_camera(child)
		if player_camera:
			return

func get_player_forward_vector() -> Vector3:
	var forward: Vector3
	if player_camera:
		forward = -player_camera.global_transform.basis.z
	else:
		forward = -player.global_transform.basis.z
	forward.y = 0
	return forward.normalized()

func is_player_looking_at_me() -> bool:
	var player_forward = get_player_forward_vector()
	var dir_to_me = player.global_position.direction_to(global_position)
	dir_to_me.y = 0
	dir_to_me = dir_to_me.normalized()
	var dot_product = player_forward.dot(dir_to_me)
	return dot_product > 0.15

func is_player_looking_directly_at_me() -> bool:
	var player_forward = get_player_forward_vector()
	var dir_to_me = player.global_position.direction_to(global_position)
	dir_to_me.y = 0
	dir_to_me = dir_to_me.normalized()
	var dot_product = player_forward.dot(dir_to_me)
	return dot_product > 0.82

func trigger_flee_sequence() -> void:
	current_state = State.FLEEING
	var flee_direction = (global_position - player.global_position).normalized()
	var raw_hiding_spot = global_position + (flee_direction * 8.0)
	flee_target_position = NavigationServer3D.map_get_closest_point(nav_agent.get_navigation_map(), raw_hiding_spot)
	nav_agent.target_position = flee_target_position

func setup_cross_dash() -> void:
	var player_forward = get_player_forward_vector()
	var player_side = Vector3(-player_forward.z, 0, player_forward.x).normalized()
	var side_direction = 1.0 if randf() > 0.5 else -1.0
	var calculated_offset = player.global_position + (player_forward * 4.0) + (player_side * (6.0 * side_direction))
	cross_dash_target = NavigationServer3D.map_get_closest_point(nav_agent.get_navigation_map(), calculated_offset)
	current_state = State.CROSS_DASHING

func start_lunge_sequence() -> void:
	current_state = State.LUNGING
	can_lunge = false
	velocity = Vector3.ZERO
	lunge_target_position = player.global_position
	
	safely_travel_to("pippa-enemy-animated_Jump") 
	await get_tree().create_timer(1.3).timeout
	if character_model: character_model.position = Vector3.ZERO
	
	current_state = State.COOLDOWN
	safely_force_start("pippa-enemy-animated_Idle")
	await get_tree().create_timer(lunge_cooldown).timeout
	can_lunge = true
	current_state = State.STALKING

func stop_lunge_instantly() -> void:
	current_state = State.COOLDOWN
	velocity = Vector3.ZERO
	if character_model: character_model.position = Vector3.ZERO
	safely_force_start("pippa-enemy-animated_Idle")
	await get_tree().create_timer(lunge_cooldown).timeout
	can_lunge = true
	current_state = State.STALKING
	
func stop_hunting_completely() -> void:
	current_state = State.COOLDOWN
	velocity = Vector3.ZERO
	can_lunge = false
	if anim_playback: 
		safely_force_start("pippa-enemy-animated_Idle")

func safely_travel_to(state_name: String) -> void:
	if anim_playback:
		if anim_playback.get_current_node() != "" and state_name != "":
			anim_playback.travel(state_name)

func safely_force_start(state_name: String) -> void:
	if anim_playback:
		anim_playback.start(state_name)
	
