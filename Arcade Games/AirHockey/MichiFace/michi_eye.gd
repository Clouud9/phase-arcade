extends Node3D

signal mouth_act(won:bool)

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var eyelid_upper:Node3D = $Eyelid
@onready var eye_left:Node3D = $Eye
@onready var eye_right:Node3D = $EyeR
@onready var eye_sparkle_left:CPUParticles3D = $Eye/EyeSparkle
@onready var eye_sparkle_right:CPUParticles3D = $EyeR/EyeSparkle

@export var target:Node3D
@export var game_controller:Node3D

var look_at_transform:Transform3D
var scale_memory:Vector3
var round_active:bool
var eyes_closed:bool = true
var timer:float = 0
var player_score_memory = 0
var opponent_score_memory = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animator.play("MichiEyeAnims/EyesOpen")
	animator.stop()
	scale_memory = self.scale
	game_controller.connect("round_active", round_changed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer+=delta
	if round_active:
		look_at_transform = self.transform.looking_at(target.position)
		#eyelid_upper.rotation.x = -45
	else:
		look_at_transform = self.transform.looking_at(game_controller.global_position)
		#eyelid_upper.rotation.x = -8
		#eyelid_upper.rotation.x = -8
	#self.transform = self.transform.interpolate_with(look_at_transform, clampf(delta * 10, 0, 1))
	#self.scale = scale_memory
	var look_at_rotation:Vector3 = look_at_transform.basis.get_euler()
	
	self.rotation = look_at_rotation.lerp(Vector3.ZERO, 0.5).clamp(Vector3(-.7, -.7, -.7), Vector3(.7, .7, .7))
	look_at_rotation.x+=PI
	#print(look_at_rotation)
	if !eyes_closed:
		eye_left.rotation = eye_left.rotation.lerp(look_at_rotation, clampf(delta * 20, 0, 1))#.lerp(Vector3.ZERO, 0.5)
		eye_right.rotation = eye_right.rotation.lerp(look_at_rotation, clampf(delta * 20, 0, 1))
	pass

func round_changed(round_over:bool, player_score:int = -1, opponent_score:int = -1):

	if round_over:
		
		#emit_signal("mouth_act", true)
		var round_number:int = player_score + opponent_score
		var player_won:bool
		if player_score > player_score_memory:
			player_won = true
		else:
			player_won = false
		player_score_memory = player_score
		round_active = false
		
		if round_number >= 1 && eyes_closed:
			animator.play("MichiEyeAnims/EyesOpen")
			eyes_closed = false
		if round_number >=2:
			emit_signal("mouth_act", player_won)
		if round_number >= 3:
			if player_won:
				animator.play("MichiEyeAnims/AngrySquint")
		if round_number >= 3:
			eye_sparkle_left.color = Color(1,0,0)
			eye_sparkle_left.scale_amount_max = clampf(1.0 + opponent_score / 3, 1, 3)
			eye_sparkle_right.color = Color(1,0,0)
			eye_sparkle_right.scale_amount_max = clampf(1.0 + opponent_score / 3, 1, 3)
			
	else:
		round_active = true
	
	pass
