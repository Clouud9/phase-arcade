extends Game
class_name JracingGame
## Jracing's root inside the arcade. Swaps between the main menu and races
## within the cabinet, where JellyJam used change_scene_to_file, which would
## replace the whole arcade.

const MENU_SCENE := "res://Arcade Games/Jracing/main_menu/main_menu.tscn"
const RACE_SCENE := "res://Arcade Games/Jracing/race/race.tscn"

@onready var current: Node = $MainMenu

## Replaces the menu or race that [param from] is in with the scene at [param path].
static func switch_to(from: Node, path: String) -> void:
	var game := Game.get_game(from) as JracingGame
	if game == null:
		push_error("JracingGame.switch_to called outside a JracingGame.")
		return
	game._swap.call_deferred(path)

func _swap(path: String) -> void:
	# Take the old scene out before adding the new one, so an old race clears
	# RaceManager.instance before the new race sets it.
	if current:
		remove_child(current)
		current.queue_free()
	current = (load(path) as PackedScene).instantiate()
	add_child(current)
