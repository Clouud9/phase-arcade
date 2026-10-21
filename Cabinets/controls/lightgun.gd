extends Node3D

@export var gun:Node3D
@export var gun_slide:Node3D
@onready var start_pos = gun.position

var active:bool

func aim_at(tgt:Vector3):
	active=true
	$ShootingPivot.look_at(tgt)
	gun.look_at(tgt)

var slide_velocity:float = 0

func fire():
	$AnimationPlayer.play("fire")

func _process(delta: float) -> void:
	#gun.global_transform = gun.global_transform.interpolate_with(%GunPos.global_transform, 1.0)
	gun.global_position = gun.global_position.move_toward(%GunPos.global_position, 1* delta)
	
	
