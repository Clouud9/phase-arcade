extends Game
class_name BlowjorbGame

const start_menu_scene = "res://Arcade Games/Blowjorb/scenes/start_menu.tscn"

var current_scene_node: Node = null

@export var my_music_player:Node
@export var my_sfx_player:Node
@export var data_keeper:Node
#1152x648
func _ready() -> void:
	# Initialize Arcade Cabinet bindings, highscores, etc.
	super._ready()
	
	# Start at the main menu
	load_sub_scene(start_menu_scene)

func load_sub_scene(scene_path: String) -> void:
	# Free the existing sub-scene (menu or previous level)
	if current_scene_node:
		current_scene_node.queue_free()
		
	var new_scene = load(scene_path)
	if new_scene:
		current_scene_node = new_scene.instantiate()
		add_child(current_scene_node)
		
		# Connect level completion signals if it's a level
		if current_scene_node.has_signal("jorb_level_completed"):
			current_scene_node.connect("jorb_level_completed", _on_level_completed)

func change_scene_to(scene_path: String) -> void:
	load_sub_scene(scene_path)

func _on_level_completed() -> void:
	pass

func _on_add_coin() -> void:
	super._on_add_coin()
	print("Coin inserted into arcade cabinet!")
	print(current_scene_node)
	if current_scene_node and current_scene_node.has_method("_on_start_pressed"):
		current_scene_node._on_start_pressed()
	
func check_high_score(final_score:int):
	#var scores:HighscoreCollection = Scores.get_highscores("Blowjorb") #<-USE WHEN THE GAME STARTS USING USER DATA FOR HIGHSCORES
	for score:Highscore in highscores.highscores:
		if final_score >score.score:
			#var new_high_score = Highscore.new()
			#new_high_score.score = final_score
			#new_high_score.player = "PENIS"
			#scores.highscores.append(new_high_score)
			#scores.highscores.sort()
			#if scores.highscores.size()>10:
				#scores.highscores.remove_at(-1)
			print("YOU'VE JOINED THE BIG DICK CLUB!!!")
			return true
	return false
