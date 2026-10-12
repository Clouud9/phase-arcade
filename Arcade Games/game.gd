extends Node
class_name Game
## A Game with arcade mechanics which can run inside an [ArcadeCabinet]
##
## It's compatible with [Control], [Node2D], and [Node3D],
## which is achieved by tricking the GDScript parser into letting us do multiple inheritence.
## If you need access to a specific node interface, use one of [method get_ui], [method get_2D], or [method get_3D] as appropriate.
##
## While none of these methods, or even the class itself, are required,
## it may help us to fix compatibility issues and such if you rely on them where you can.

## [SFXPlayer] node in the game, if any, to route [method play_sfx] calls to
@export var sfx_player: SFXPlayer

# --- Management ---

## For use inside your game, it doesn't control anything currently
signal game_lost
## Emits [signal game_lost], and can be inhereted to do more than that
func lose():
	game_lost.emit()

## For use inside your game, it doesn't control anything currently
signal game_won
## Emits [signal game_won], and can be inhereted to do more than that
func win():
	game_won.emit()

var score = 0
signal score_changed(score: int) ## Only triggered by [method add_score]. Modifying [member score] has no effect
func add_score(points: int):
	score += points
	score_changed.emit(score)

## TODO: stub
## Usually adding coins will grant an extra play, some more lives, or a revive. It's up to you
func add_coin():
	pass

# --- Accessors ---

## Returns the [Game], if any, that [param from] is inside of
static func get_game(from: Node) -> Game:
	while from and from is not Game:
		from = from.get_parent()
	return from

## Plays SFX via the [Game]'s [member Game.sfx_player].
##
## See [method SFXPlayer.play_sfx] for more info
static func play_sfx(from:Node, effect_name:StringName) -> SFXPlayer.SFXControl:
	var game = get_game(from)
	if not game or not game.sfx_player:
		return null
	return game.sfx_player.play_sfx(effect_name)

# --- Multiple Inheritence ---

var _self_ui:Control
var _self_2D:Node2D
var _self_3D:Node3D

## If the parent [Game] exists, is ready, and is a [Control], return the [Control] interface.
## Otherwise error
static func get_ui(from:Node) -> Control:
	var g = get_game(from)
	assert(g)
	assert(g.is_node_ready())
	assert(g._self_ui != null)
	return g._self_ui

## If the parent [Game] exists, is ready, and is a [Node2D], return the [Node2D] interface.
## Otherwise error
static func get_2D(from:Node) -> Node2D:
	var g = get_game(from)
	assert(g)
	assert(g.is_node_ready())
	assert(g._self_2D != null)
	return g._self_2D

## If the parent [Game] exists, is ready, and is a [Node3D], return the [Node3D] interface.
## Otherwise error
static func get_3D(from:Node) -> Node3D:
	var g = get_game(from)
	assert(g)
	assert(g.is_node_ready())
	assert(g._self_3D != null)
	return g._self_3D

# --- Main ---

func _ready() -> void:
	var _self = self as Node
	if _self is Control:
		_self_ui = _self
		_self_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	elif _self is Node2D:
		_self_2D = _self
	elif _self is Node3D:
		_self_3D = _self
	else:
		assert(false) #TODO: more helpful error message, maybe config warning
