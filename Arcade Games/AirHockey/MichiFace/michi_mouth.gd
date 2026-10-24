extends Node3D

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var skeleton:Skeleton3D = $Skeleton3D

@export var face_parent:Node3D

var uncollapsed:Transform3D
var collapsed:Transform3D = Transform3D.IDENTITY
var mouth_visible:bool = false
var visibility_lerp:float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	uncollapsed = skeleton.get_bone_global_pose(skeleton.find_bone("LipDriver"))
	collapsed = collapsed.scaled(Vector3(1,.8,.01))
	skeleton.set_bone_global_pose(skeleton.find_bone("LipDriver"), collapsed)
	face_parent.connect("mouth_act", taunt)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#animator.play("Take 001")
	pass

func show_mouth():
	while !mouth_visible:
		visibility_lerp += get_process_delta_time()
		print("mouth unhiding", visibility_lerp)
		skeleton.set_bone_global_pose(skeleton.find_bone("LipDriver"), collapsed.interpolate_with(uncollapsed, clampf(visibility_lerp, 0, 1)))
		print(skeleton.get_bone_global_pose(skeleton.find_bone("LipDriver")))
		await get_tree().create_timer(0, false).timeout
		if visibility_lerp > 1:
			mouth_visible = true
			
func taunt(won:bool):
	if !mouth_visible:
		show_mouth()
	else:
		animator.play("Take 001")
		if won:
			#play a happy taunt animation
			pass
		else:
			#play an angry taunt animation
			pass
