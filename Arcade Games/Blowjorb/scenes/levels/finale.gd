extends Control

@onready var retry_value: Label = $Menu/HBoxRetries/Value
@onready var blow_value: Label = $Menu/HBoxBlows/Value
@onready var time_value: Label = $Menu/HBoxTime/Value
@onready var score_value: Label = $Menu/HBoxScore/Value
@onready var menu_button: Button = $Menu/Menu/Control/MenuButton

const UNIVERSFIELD_MESSAGE_PING_351298 = preload("uid://dpq2pb5mevtpd")

var my_music_player
var my_sfx_player
var data_keeper

# Optional: Add a reference to your cursor node (e.g., a TextureRect, Label, or Sprite2D)
# Make sure to place your cursor node in the scene and assign its path here, 
# or comment this out if you just want to use Godot's built-in button focus styles.

@onready var cursor: Control = $Cursor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	my_sfx_player = get_parent().my_sfx_player
	my_music_player = get_parent().my_music_player
	data_keeper = get_parent().data_keeper

	# 2. Automatically select the menu/retry button when the screen opens
	menu_button.grab_focus()
	
	# Load stats logic...
	var jorbs = 0
	var blows = 0
	var time = 0
	for i in data_keeper.level_stats.values():
		jorbs += i["retries"]
		blows += i["blows"]
		time += i["time"]
		
	blow_value.text = str(blows)
	retry_value.text = str(jorbs)
	time_value.text = time_in_seconds(time)
	var final_score = get_parent().score
	score_value.text = str(final_score)
	var is_high_score = get_parent().check_high_score(final_score)
	
	var next_screen = "res://Arcade Games/Blowjorb/scenes/levels/high_scores.tscn" if not is_high_score else "res://Arcade Games/Blowjorb/scenes/levels/submit_score.tscn"
	
	menu_button.pressed.connect(func(): 
		my_sfx_player.play(UNIVERSFIELD_MESSAGE_PING_351298,false,false)
		var start_menu_resource = load(next_screen)
		if start_menu_resource:
			var start_menu = start_menu_resource.instantiate()
			get_parent().add_child(start_menu)
			await start_menu.is_node_ready()
			queue_free()
	)		

func _process(_delta: float) -> void:
	# 3. Update the visual cursor position to match the currently focused button
	if cursor:
		var focused_control = get_viewport().gui_get_focus_owner()
		if focused_control is Button:
			cursor.visible = true
			# Position the cursor to the left of the focused button with a small offset (e.g., -30 pixels)
			cursor.global_position = focused_control.global_position + Vector2(-30, focused_control.size.y / 2.0 - cursor.size.y / 2.0)
		else:
			cursor.visible = false

func time_in_seconds(t):
	var minutes = int(t / 60)
	var seconds = int(t - minutes * 60)
	var milliseconds = "%2f" % t
	var min_str = str(minutes) if minutes > 9 else "0" + str(minutes)
	var sec_str = str(seconds) if seconds > 9 else "0" + str(seconds)
	var mil_str = str(milliseconds.substr(1)) if milliseconds.length() > 1 else "0" + str(milliseconds.substr(1))
	var time_passed_formatted = min_str + ":" + sec_str + "´" + str(milliseconds.substr(2, 2))
	return time_passed_formatted
