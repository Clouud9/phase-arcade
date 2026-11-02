extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

# ASSIGN YOUR PEDESTAL/DISPLAY MODELS IN THE INSPECTOR
@export var silver_mesh_path: NodePath
@export var gold_mesh_path: NodePath

@onready var camera_3d: Camera3D = $Camera3D

# PATH REFERENCES
@onready var lantern_light: OmniLight3D = $Camera3D/lantern/OmniLight3D
@onready var overlay_panel: ColorRect = $FadeScreen/Overlay
@onready var win_label: Label = $FadeScreen/WinLabel

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var rotation_input: Vector2 = Vector2.ZERO
var L = 0
var R = 0
var U = 0
var D = 0
var swingState = 0

# Knockdown, Jumpscare, and Win Trackers
var controls_enabled: bool = true
var target_camera_pitch: float = 0.0
var is_camera_pitching: bool = false
var base_light_energy: float = 1.0
var is_game_won: bool = false

# Local Inventory Trackers
var has_silver_item: bool = false
var has_gold_item: bool = false

func _ready() -> void:
	if lantern_light:
		base_light_energy = lantern_light.light_energy
		
	if overlay_panel:
		overlay_panel.color = Color(0, 0, 0, 0)
		
	if win_label:
		win_label.modulate.a = 0.0

func _input(event: InputEvent) -> void:
	if not controls_enabled:
		return
		
	if event.is_action_pressed("left"): L = 1
	if event.is_action_pressed("right"): R = 1
	if event.is_action_pressed("up"): U = 1
	if event.is_action_pressed("down"): D = 1
	if event.is_action_released("left"): L = 0
	if event.is_action_released("right"): R = 0
	if event.is_action_released("up"): U = 0
	if event.is_action_released("down"): D = 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Hard freeze player inputs completely if the game is won or pitching
	if is_game_won:
		velocity.x = move_toward(velocity.x, 0, speed * 2 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 2 * delta)
		move_and_slide()
		return

	if is_camera_pitching:
		camera_3d.rotation.x = move_toward(camera_3d.rotation.x, deg_to_rad(85.0), 4.0 * delta)
		
		if lantern_light and lantern_light.light_energy > 0.05:
			lantern_light.light_energy = randf_range(0.0, lantern_light.light_energy * 0.95)
			
		velocity.x = move_toward(velocity.x, 0, speed * 2 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 2 * delta)
		move_and_slide()
		return 

	var input_dir: Vector2 = Vector2(L - R,  D - U)
	var direction: Vector3 = (transform.basis * Vector3(0, 0, input_dir.y)).normalized()
	
	rotate_y(input_dir.x * delta)
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

# --- FIXED PUBLIC REVEAL CONTROLLER (RUNTIME DESYNC RESOLUTION) ---
func reveal_collected_mesh(type: String) -> void:
	if type == "silver" and silver_mesh_path:
		# Fetch the node dynamically right now instead of caching in _ready()
		var silver_node = get_node_or_null(silver_mesh_path)
		if silver_node:
			silver_node.visible = true
			print("Runtime Fix: Silver mesh successfully turned VISIBLE!")
		else:
			print("CRITICAL ERROR: Player cannot find Silver Mesh path! Check your Inspector link.")
			
	elif type == "gold" and gold_mesh_path:
		var gold_node = get_node_or_null(gold_mesh_path)
		if gold_node:
			gold_node.visible = true
			print("Runtime Fix: Gold mesh successfully turned VISIBLE!")
		else:
			print("CRITICAL ERROR: Player cannot find Gold Mesh path! Check your Inspector link.")

# --- PUBLIC VICTORY TRIGGER (FADE TO WHITE + FADE IN TEXT + WIN SIGNAL) ---
func trigger_victory() -> void:
	if is_game_won: return 
	
	is_game_won = true
	controls_enabled = false
	L = 0; R = 0; U = 0; D = 0
	
	print("VICTORY! The curse is broken!")
	
	var win_tween = create_tween().set_parallel(true)
	
	if overlay_panel:
		overlay_panel.color = Color(1, 1, 1, 0) 
		win_tween.tween_property(overlay_panel, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if win_label:
		win_tween.tween_property(win_label, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if lantern_light:
		win_tween.tween_property(lantern_light, "light_energy", base_light_energy * 5.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await win_tween.finished
	await get_tree().create_timer(3.0).timeout
	
	# The level is reset by the title screen before the next coin
	Game.get_game(self).win()

# --- JUMPSCARE DEFEAT FLOW (FADE TO BLACK + LOSE SIGNAL) ---
func get_knocked_down() -> void:
	if not controls_enabled or is_game_won: return 
	
	controls_enabled = false
	is_camera_pitching = true
	L = 0; R = 0; U = 0; D = 0
	
	var fade_tween = create_tween().set_parallel(true)
	if overlay_panel:
		overlay_panel.color = Color(0, 0, 0, 0) 
		fade_tween.tween_property(overlay_panel, "color:a", 1.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if lantern_light:
		fade_tween.tween_property(lantern_light, "light_energy", 0.0, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		
	await fade_tween.finished
	await get_tree().create_timer(2.5).timeout
	
	# The level is reset by the title screen before the next coin
	Game.get_game(self).lose()
