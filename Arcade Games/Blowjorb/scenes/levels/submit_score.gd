extends Control

@onready var letters: HBoxContainer = $Menu/HBoxTime/Letters
@onready var score_label: Label = $Menu/ScoreLabel

var it:InputTracker 
var my_music_player
var my_sfx_player
var data_keeper

const UNIVERSFIELD_MESSAGE_PING_351298 = preload("uid://dpq2pb5mevtpd")
const THUD = preload("uid://duxah1r3kofo6")
const AWAWA = preload("uid://c10pgrlp6fq1w")

var letter_arr
var cursor:int = 0
var alphabet_cursor:int = 0
var alphabet:Array=["A","B","C","D","E","F","G","H","I","J","K","L","M",
					"N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

var final_score
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	it =  ArcadeCabinet.get_input_state(self)
	my_sfx_player = get_parent().my_sfx_player
	my_music_player = get_parent().my_music_player
	data_keeper = get_parent().data_keeper
	final_score = get_parent().score
	letter_arr = [
	{"node":letters.get_children()[0],
					"locked":false,
					"value":"A"
					},
	{"node":letters.get_children()[1],
					"locked":false,
					"value":"A"
					},
	{"node":letters.get_children()[2],
					"locked":false,
					"value":"A"
					},
		]
	update_cursor()
	score_label.text = "FINAL SCORE: "+str(final_score)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if it._input_up:
		#if alphabet_cursor == 0:
			#alphabet_cursor = alphabet.size()-1
		#else:
			#alphabet_cursor-=1
		#update_cursor()
		#my_sfx_player.play(THUD,false,false)
	#if it._input_down:
		#if alphabet_cursor ==  alphabet.size()-1:
			#alphabet_cursor = 0
		#else:
			#alphabet_cursor+=1
		#update_cursor()
		#my_sfx_player.play(THUD,false,false)

		
				

func update_cursor():
	for i in range(letter_arr.size()-1):
		if i == cursor:
			letter_arr[cursor]["node"].modulate=Color.WHITE
			
		elif letter_arr[i]["locked"]:
			letter_arr[cursor]["node"].modulate=Color.YELLOW
		else:
			letter_arr[cursor]["node"].modulate=Color(0.098, 0.729, 0.788, 1.0)
	letter_arr[cursor]["node"].text=alphabet[alphabet_cursor]
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		if alphabet_cursor == 0:
			alphabet_cursor = alphabet.size()-1
		else:
			alphabet_cursor-=1
		update_cursor()
		my_sfx_player.play(THUD,false,false)
	if event.is_action_pressed("ui_down"):
		if alphabet_cursor ==  alphabet.size()-1:
			alphabet_cursor = 0
		else:
			alphabet_cursor+=1
		update_cursor()
		my_sfx_player.play(THUD,false,false)
	if event.is_action_pressed("ui_accept"):
		var complete=true
		for letter in letter_arr:
			if letter["locked"] == false:
				complete = false
				break
		if complete:
			#save score here
			my_sfx_player.play(UNIVERSFIELD_MESSAGE_PING_351298,false,false)
			
			#var scores:HighscoreCollection = Scores.get_highscores("Blowjorb") #<-USE WHEN THE GAME STARTS USING USER DATA FOR HIGHSCORES
			var scores = get_parent().highscores
			var name:String
			for letter in letter_arr:
				name+=letter["value"]
			var new_score = Highscore.new()
			new_score.player = name
			new_score.score = final_score
			scores.highscores.remove_at(-1)
			scores.highscores.append(new_score)
			scores.highscores.sort_custom(func(a, b):return a.score > b.score)
			
			var start_menu_resource = load("res://Arcade Games/Blowjorb/scenes/levels/high_scores.tscn")
			if start_menu_resource:
				var start_menu = start_menu_resource.instantiate()
				get_parent().add_child(start_menu)
				await start_menu.is_node_ready()
				queue_free()
		else:
			letter_arr[cursor]["locked"] = true
			letter_arr[cursor]["value"] = alphabet[alphabet_cursor]
			if cursor <2:
				cursor+=1
				alphabet_cursor = 0
			update_cursor()
			my_sfx_player.play(AWAWA,false,false)
