extends RigidBody3D

@export var sound_ricochet: AudioStreamPlayer3D
@export var sound_ricochet2: AudioStreamPlayer3D
@export var sound_goal: AudioStreamPlayer3D
@export var sound_hit: AudioStreamPlayer3D
#var bumper_sound = preload("res://Arcade Games/AirHockey/BellHit-206700 - Railroad Crossing Signal Bell - Loop.wav")
var velocity_last_frame:float
var flipflop:bool = false
var cooldown:int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect("body_entered", hit_something)
	#body_entered.connect(hit_something)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(get_contact_count())
	pass

func _physics_process(delta: float) -> void:


	velocity_last_frame = linear_velocity.length()
	pass

func _integrate_forces(state:PhysicsDirectBodyState3D):

	linear_velocity = linear_velocity.limit_length(5)
	#print(linear_velocity.length())
	var attack:float = 0
	if cooldown > 0:
		cooldown -= 1
	else:
		if state.linear_velocity.length() > 1.0:
			for contact_index:int in state.get_contact_count():
				if state.get_contact_collider_object(contact_index).name == "StaticBodyBumpers":
					attack = clampf(2 * abs(state.get_contact_local_normal(contact_index).dot(linear_velocity.normalized())), 0, 1)
					#sound_player.volume_linear = clampf(linear_velocity.length() / 16.0, 0.1,1.0)
					if abs(linear_velocity.z) < 0.01:
						print(linear_velocity.z)
						linear_velocity = linear_velocity.rotated(Vector3.UP, randf_range(-10, 10))
	if attack > 0.1:
		cooldown = 1
		flipflop = !flipflop
		if flipflop:
			sound_ricochet.volume_linear = attack * clampf( linear_velocity.length() / 16.0, 0.1,1.0)
			sound_ricochet.play()
		else:
			sound_ricochet2.volume_linear = attack * clampf( linear_velocity.length() / 16.0, 0.1,1.0)
			sound_ricochet2.play()


func hit_something():
	sound_ricochet.play()
	print("puckhit")
	for node in get_colliding_bodies():
		if node.name == "StaticBodyBumpers":
			sound_ricochet.play()
			pass
