@tool
extends VBoxContainer
class_name HighscoreContainer

@export var fixed_length:int = 0:
	set(i):
		if i >= 0:
			fixed_length = i
@export var highscore_collection:HighscoreCollection:
	set(value):
		highscore_collection = value
		populate()

@export_tool_button("populate") var populate_button = populate

func _ready() -> void:
	if Engine.is_editor_hint():
		populate()
		return
	if not highscore_collection:
		var game = await Game.get_ready_game(self)
		if game:
			highscore_collection = game.highscores
			game.highscores_updated.connect(populate)
	populate()

func populate() -> void:
	if not is_node_ready() or not highscore_collection:
		return
	for child in get_children():
		if child is HighscoreLabel:
			remove_child(child)
			child.queue_free()
	var entries = highscore_collection.highscores
	entries.sort_custom(func(a, b):
		if not a:
			return false
		if not b:
			return true
		return a.score > b.score)
	var count = fixed_length if fixed_length > 0 else entries.size()
	for i in range(count):
		var label := HighscoreLabel.new()
		if i < entries.size() and entries[i]:
			label.player = entries[i].player
			label.score = entries[i].score
		add_child(label)
