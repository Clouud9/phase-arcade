extends RigidBody3D

signal has_failed
signal has_succeeded

var sound_effects: Array[AudioStream] = [
	preload("res://Arcade Games/Blowjorb/assets/audio/blow1.mp3"),
	preload("res://Arcade Games/Blowjorb/assets/audio/blow2.mp3"),
	preload("res://Arcade Games/Blowjorb/assets/audio/blow3.mp3"),
	preload("res://Arcade Games/Blowjorb/assets/audio/awawa.mp3"),
	preload("res://Arcade Games/Blowjorb/assets/audio/Happy Wheels victory green screen.mp3"),
	preload("res://Arcade Games/Blowjorb/assets/audio/thud.mp3"),
	preload("res://Arcade Games/Blowjorb/assets/audio/aaa.mp3"),
	preload("res://Arcade Games/Blowjorb/assets/audio/aaa2.mp3")
]

var start_timestamp = 0
var time_passed = 0
var retries: int = 1
var blows: int = 0

var was_on_floor: bool 
var prev_lv: Vector3
var bounce_cd_complete: bool = true

@export var rolling_force := 10
@export var keyboard_rotation_speed: float = 3.0 # Speed for rotating camera with arrow keys
@export var min_pitch: float = -deg_to_rad(60) 
@export var max_pitch: float = deg_to_rad(60)

@onready var camera_rig: Marker3D = $CameraRig

var start_pos: Vector3
var failed := false
var level_complete := false

@onready var jail_label: Label = $JUI/JailLabel
@onready var juccess_label: Label = $JUI/JuccessLabel
@onready var timer_label: Label = $JUI/Jime
@onready var level_complete_timer: Timer = $LevelCompleteTimer

@onready var level_completed_menu: CanvasLayer = $LevelCompletedMenu
@onready var time_value: Label = %TimeValue
@onready var retries_value: Label = %RetriesValue
@onready var blows_value: Label = %BlowsValue
const base_score:int = 6700
@onready var time_score: Label = %TimeScore
@onready var jorb_score: Label = %JorbScore
@onready var blow_score: Label = %BlowScore
@onready var final_score: Label = %FinalScore

@onready var next_button: Button = %nextButton
@onready var quit_button: Button = %quitButton

@onready var animated_sprite_2d: AnimatedSprite2D = $BlowingIt/AnimatedSprite2D

var it:InputTracker 
var my_music_player
var my_sfx_player
var data_keeper

func _ready() -> void:
	it =  ArcadeCabinet.get_input_state(self)
	my_sfx_player = get_parent().my_sfx_player
	my_music_player = get_parent().my_music_player
	data_keeper = get_parent().data_keeper
	jail_label.hide()
	juccess_label.hide()
	camera_rig.top_level = true
	
	# Keep mouse visible since we're using keyboard control now
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	start_pos = global_position
	has_failed.connect(_on_fail)
	has_succeeded.connect(_on_success)
	level_completed_menu.hide()
	level_complete_timer.timeout.connect(_on_level_timer_timeout)
	start_timestamp = Time.get_unix_time_from_system()

# Camera rotation is handled in _process via Arrow Keys

func _process(delta: float) -> void:
	if not my_music_player or not my_sfx_player or not data_keeper:
		my_sfx_player = get_parent().my_sfx_player
		my_music_player = get_parent().my_music_player
		data_keeper = get_parent().data_keeper
	camera_rig.global_position = global_position
	timer_label.text = time_in_seconds(time_passed)
	time_passed = Time.get_unix_time_from_system() - start_timestamp
	

	# Camera rotation using Arrow Keys (disabled if level is complete/failed)
	if not level_complete and not failed:
			camera_rig.rotate_y(-it.movement.x * keyboard_rotation_speed * delta)
			camera_rig.rotate_x(it.movement.y * keyboard_rotation_speed * delta)
		
	# Clamp pitch and lock z rotation
	camera_rig.rotation.x = clamp(camera_rig.rotation.x, min_pitch, max_pitch)
	camera_rig.rotation.z = 0

func _physics_process(delta: float) -> void:
	# Bouncing sound solution 
	var hits = get_colliding_bodies().size()
	var is_on_floor = hits > 0
	if is_on_floor and not was_on_floor:
		var dir_before = prev_lv.normalized()
		var dir_after = linear_velocity.normalized()
		var dir_match = dir_before.dot(dir_after)
		if dir_match < 0.85:
			my_sfx_player.play(sound_effects[5], false)
			
	if failed:
		# Restart using Spacebar (ui_accept) or custom restart action
		if it.firing:
			restart()

	was_on_floor = is_on_floor
	prev_lv = linear_velocity

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("ui_accept"):
		if not failed and not level_complete:
			push_ball_forward()
			
func push_ball_forward():
	var forward_dir: Vector3 = -camera_rig.global_transform.basis.z
	forward_dir.y = 0
	forward_dir = forward_dir.normalized()
	
	apply_central_impulse(forward_dir * rolling_force)
	blows += 1
	my_sfx_player.play(sound_effects[2], false, true)
	animated_sprite_2d.play("default")
	
func restart():
	failed = false
	global_position = start_pos
	camera_rig.rotation = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	jail_label.hide()
	retries += 1
	my_sfx_player.play(sound_effects[randi_range(6, 7)], false)

func _on_fail() -> void:
	failed = true
	jail_label.show()
	
func _on_success() -> void:
	level_complete = true
	juccess_label.show()
	my_sfx_player.play(sound_effects[3], false)
	my_sfx_player.play(sound_effects[4], false)
	time_value.text = time_in_seconds(time_passed)
	time_score.text = str(int(-1*time_passed*10))+"(T-BONUS)"
	blow_score.text = str(int(-1*blows*100))+"(B-BONUS)"
	var jorb_text
	if retries == 1:
		jorb_text = "x2"
	elif retries == 2:
		jorb_text = "x1" 
	else:
		jorb_text = -1*200*retries
	jorb_score.text = str(jorb_text)+"(J-BONUS)"
	retries_value.text = str(retries*100)
	blows_value.text = str(blows)
	
	var final_score_value = int(base_score-(blows*100)-(time_passed*10))
	if jorb_text is String:
		if  jorb_text == "x2":
			final_score_value*=2
	elif jorb_text < 0:
		final_score_value = final_score_value+jorb_text
	final_score_value = max(final_score_value,0)
	final_score.text = str(final_score_value)
	get_parent().get_parent().add_score(final_score_value)
	get_parent().jorb_level_completed.emit()
	level_complete_timer.start()
	
func _on_level_timer_timeout():	
	level_completed_menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Instantly give focus to the next button so arrow keys and spacebar work right away
	next_button.grab_focus()
	
func time_in_seconds(t):
	var minutes = int(t / 60)
	var seconds = int(t - minutes * 60)
	var milliseconds = "%2f" % t
	var min_str = str(minutes) if minutes > 9 else "0" + str(minutes)
	var sec_str = str(seconds) if seconds > 9 else "0" + str(seconds)
	var mil_str = str(milliseconds.substr(1)) if milliseconds.length() > 1 else "0" + str(milliseconds.substr(1))
	var time_passed_formatted = min_str + ":" + sec_str + "´" + str(milliseconds.substr(2, 2))
	return time_passed_formatted
	
func temu_is_on_floor():
	if abs(linear_velocity.y) > 0.2: 
		return false
		
	for body in get_colliding_bodies():
		var state = PhysicsServer3D.body_get_direct_state(get_rid())
		for i in range(state.get_contact_count()):
			if state.get_contact_collider_object(i) == body:
				var normal = state.get_contact_local_normal(i)
				if normal.dot(Vector3.DOWN) > -1:
					return true
	return false
