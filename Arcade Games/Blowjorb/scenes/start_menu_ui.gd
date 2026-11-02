extends Control



@export var start_button : Button

@export var menu: VBoxContainer
@export var main_settings: VBoxContainer
@export var video_settings: VBoxContainer
@export var audio_settings: VBoxContainer
@export var controls_settings: VBoxContainer
@export var language_settings: VBoxContainer
const UNIVERSFIELD_MESSAGE_PING_351298 = preload("uid://dpq2pb5mevtpd")
const bgm = preload("uid://cw7422abmjmbv") #spooky kooky dog

var my_music_player
var my_sfx_player
var data_keeper
# Optional: Assign your visual cursor node here in the Inspector
@export var cursor: Control

var nav_stack: Array[Control] = []
var current_panel: Control

func _ready():
	my_sfx_player = get_parent().my_sfx_player
	my_music_player = get_parent().my_music_player
	data_keeper = get_parent().data_keeper
	get_parent().score = 0
	current_panel = menu
	_show_panel(menu)
	start_button.pressed.connect(_on_start_pressed)

	my_music_player.play(bgm, true)
	
	
	# Initial focus on the start button
	_focus_first_button_in_panel(menu)

func _process(_delta: float) -> void:
	# Keep the cursor following the focused button
	if cursor:
		var focused_control = get_viewport().gui_get_focus_owner()
		if focused_control is Button and focused_control.is_visible_in_tree():
			cursor.visible = true
			cursor.global_position = focused_control.global_position + Vector2(-30, focused_control.size.y / 2.0 - cursor.size.y / 2.0)
		else:
			cursor.visible = false

func _show_panel(panel: Control):
	panel.visible = true


func _navigate_to(panel: Control):
	if current_panel:
		nav_stack.append(current_panel)
		current_panel.visible = false

	current_panel = panel
	_show_panel(current_panel)
	_focus_first_button_in_panel(current_panel)



# Finds the first focusable Button inside a panel and grabs focus
func _focus_first_button_in_panel(panel: Control) -> void:
	pass
	#if not panel:
		#return
		#
	#for child in panel.get_children():
		#if child is Button and child.visible and child.focus_mode != FOCUS_NONE:
			#child.grab_focus()
			#return
		#elif child is Control:
			## Recursive search in case buttons are nested deeper in containers
			#for sub_child in child.get_children():
				#if sub_child is Button and sub_child.visible and sub_child.focus_mode != FOCUS_NONE:
					#sub_child.grab_focus()
					#return


func _on_start_pressed():
	my_sfx_player.play(UNIVERSFIELD_MESSAGE_PING_351298, false, true)
	data_keeper.run_started.emit()
	
	var next_scene_resource = load("res://Arcade Games/Blowjorb/scenes/levels/level_1.tscn")
	var next_scene = next_scene_resource.instantiate()
	
	get_parent().add_child(next_scene)
	await next_scene.is_node_ready()
	queue_free()
