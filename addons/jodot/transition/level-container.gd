class_name LevelContainer
extends Node

@export var current_level_scene: PackedScene = null
var current_level: Node = null

var curtain:Curtain

func _ready() -> void:
	if curtain:
		# start shut, so the first level doesn't pop in
		curtain.close()
	if current_level_scene:
		load_scene(current_level_scene)

## Instantiates [param scn] and makes it the pending level. Does not touch the
## tree; call [method commit] (or use [method transition_to]) to swap it in.
func load_scene(scn: PackedScene) -> Node:
	if current_level and current_level.get_parent():
		remove_child(current_level)
		current_level.queue_free()
		remove_child(current_level)
	current_level_scene = scn
	current_level = scn.instantiate()
	add_child(current_level)
	return current_level

## Closes the curtain, swaps to [param scn], and reopens.
##
## Nodes in [param bring] are carried over into the new level, reparented
## under [param entrypoint] with their positions preserved. Use this to keep
## the player, or anything else that should survive a level change.
func transition_to(scn: PackedScene, bring: Array[Node] = [], entrypoint: NodePath = ^"") -> void:
	if curtain:
		await curtain.close()

	var loaded := load_scene(scn)
	if not bring.is_empty():
		var target: Node = loaded.get_node_or_null(entrypoint) if entrypoint else loaded
		if not target:
			push_error("LevelContainer: entrypoint '%s' not found in the new level" % entrypoint)
			target = loaded
		for n in bring:
			var relative_position = (n as Node2D).position if n is Node2D else Vector2.ZERO
			# owner ties a node to the scene it was saved in; it has to go
			# before the node can be reparented into a different one
			n.owner = null
			n.reparent(target)
			if n is Node2D:
				n.position = relative_position
			n.reset_physics_interpolation()
	curtain.open()

## Reloads [member current_level_scene] from scratch.
func reset_level() -> void:
	await transition_to(current_level_scene)
