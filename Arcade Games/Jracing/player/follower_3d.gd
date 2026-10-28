extends Sprite3D
class_name Follower3D

var target: Node2D
var scale_: float
var tag: Label = null

func _ready() -> void:
	var vp: SubViewport = RaceManager.instance.track.get_parent()
	var mesh: Node3D = vp.get_parent()
	scale_ = mesh.scale.x / vp.size.x

func _process(_delta: float) -> void:
	var xy: Vector2 = target.global_position * scale_
	position = Vector3(xy.x, scale.y, xy.y)
	rotation = get_viewport().get_camera_3d().global_rotation
	if target is JracingPlayer:
		(%Shadow as Node3D).visible = true
		rotation = Vector3(0, PI/2 - (target as JracingPlayer).direction, 0)
		if get_viewport().get_camera_3d().basis.z.dot(basis.z) < 0:
			var f := (target as JracingPlayer).sprite_state
			if RaceManager.instance.time & 8 == 0:
				f += 4
			frame = f
		else:
			frame = 8
		
		var distance := -get_viewport().get_camera_3d().to_local(position).z
		if tag != null:
			if distance > 1.5 and distance < 16:
				tag.visible = true
				tag.text = (target as JracingPlayer).player_name
				tag.position = (
					get_viewport().get_camera_3d().unproject_position(position + Vector3(0, 1.4, 0)) +
					Vector2.LEFT * (tag.size.x / 2)
				)
			else:
				tag.visible = false
		(target as JracingPlayer).can_be_seen = distance > -1 and distance < 65
			
			
