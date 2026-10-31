extends AnimatableBody2D

@export var texture: Texture2D
@export var framerate: float

var follower: Follower3D = null
var time: float = 0

func _process(delta: float) -> void:
	if follower == null:
		follower = preload("res://player/follower_3d.tscn").instantiate()
		follower.target = self
		follower.hframes = 3
		follower.vframes = 1
		follower.texture = texture
		RaceManager.instance.add_child(follower)
	
	time += delta * framerate
	if time > 4:
		time -= 4
	
	if time < 1:
		follower.frame = 0
	elif time > 2 and time < 3:
		follower.frame = 2
	else:
		follower.frame = 1
