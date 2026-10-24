extends Node
const SCORES_DIR := "user://highscores"

func _ensure_dir():
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("highscores"):
		dir.make_dir("highscores")

func _get_path(id: StringName) -> String:
	return SCORES_DIR + "/" + str(id) + ".tres"

func get_highscores(id: StringName) -> HighscoreCollection:
	_ensure_dir()
	var path := _get_path(id)
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is HighscoreCollection:
			print("[Scores] Loaded %s (%d entries)" % [path, res.highscores.size()])
			return res
		push_warning("[Scores] %s exists but isn't a HighscoreCollection" % path)
	# Create a new empty collection if none exists
	print("[Scores] No save for %s, starting fresh" % id)
	var collection := HighscoreCollection.new()
	return collection

func save_highscores(id: StringName, highscores: HighscoreCollection) -> void:
	_ensure_dir()
	var path := _get_path(id)
	var err := ResourceSaver.save(highscores, path)
	if err != OK:
		push_error("[Scores] Failed to save %s: %s" % [id, error_string(err)])
	else:
		print("[Scores] Saved %s (%d entries)" % [path, highscores.highscores.size()])

func add_highscore(id: StringName, hs: Highscore) -> void:
	print("[Scores] Adding %s for %s" % [hs, id])
	var collection := get_highscores(id)
	collection.highscores.append(hs)
	save_highscores(id, collection)

func clear_highscores(id: StringName) -> void:
	print("[Scores] Clearing %s" % id)
	var collection := HighscoreCollection.new()
	save_highscores(id, collection)
