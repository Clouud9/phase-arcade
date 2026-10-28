extends Area2D

func touch(body: Node2D) -> void:
	var player := body as JracingPlayer
	if player != null:
		player.controller.boost()
