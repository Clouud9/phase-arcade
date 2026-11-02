extends Control

@onready var menu: VBoxContainer = $Menu
@onready var h_box_time: HBoxContainer = $Menu/HBoxTime
const UNIVERSFIELD_MESSAGE_PING_351298 = preload("uid://dpq2pb5mevtpd")

var it:InputTracker 
var my_music_player
var my_sfx_player
var data_keeper
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		it =  ArcadeCabinet.get_input_state(self)
		my_sfx_player = get_parent().my_sfx_player
		my_music_player = get_parent().my_music_player
		data_keeper = get_parent().data_keeper
		
		var scores:HighscoreCollection = Scores.get_highscores("Blowjorb")
		scores = get_parent().highscores
		for score:Highscore in scores.highscores:
			print(score.player," ",score.score)
			var new_score_line = h_box_time.duplicate()
			new_score_line.get_children()[0].text = score.player
			new_score_line.get_children()[1].text = str(score.score)
			menu.add_child(new_score_line)
		menu.remove_child(h_box_time)


		
			
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		my_sfx_player.play(UNIVERSFIELD_MESSAGE_PING_351298,false,false)
		var start_menu_resource = load("res://Arcade Games/Blowjorb/scenes/start_menu.tscn")
		if start_menu_resource:
			var start_menu = start_menu_resource.instantiate()
			get_parent().add_child(start_menu)
			await start_menu.is_node_ready()
			get_parent().current_scene_node = start_menu
			queue_free()
