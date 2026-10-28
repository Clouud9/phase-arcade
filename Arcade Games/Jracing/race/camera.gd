extends Camera3D
class_name Camera

@export var distance: float
@export var height: float

@onready var track: Node3D = %Track
@onready var track_camera: Node2D = %TrackCamera
@onready var lap: Label = %Lap

var target: Follower3D
var angle: float

func _process(_delta: float) -> void:
	var player := target.target as JracingPlayer
	if player.update_direction:
		angle = player.direction + PI
	position = target.position + Vector3(cos(angle), height / distance, sin(angle)) * distance
	look_at(target.position)
	
	lap.text = " LAP %s/%s " % [
		clampi(player.lap, 1, RaceManager.track_data.laps),
		RaceManager.track_data.laps
	]
	
	var tp2 := target.target.global_position.floor()
	track_camera.position = tp2
	track.position = Vector3(tp2.x, 0, tp2.y) * target.scale_
