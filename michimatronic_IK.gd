extends Node3D
@onready var debug_draw: DebugDraw3D = $DebugDraw3D

@onready var target_node:Node3D = $Skeleton3D/TargetDummy
@onready var hand_xform:Node3D = $Skeleton3D/TargetDummy/Target_hand
@onready var skeleton:Skeleton3D = $Skeleton3D
@onready var skeletonIK:SkeletonIK3D = $Skeleton3D/SkeletonIK3D

@export var hand_target:Node3D
@export var hand_offset:Vector3

var relative_transform:Transform3D

var hand_index:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	skeletonIK.start()
	hand_index = skeleton.find_bone("Bip001 R Hand")
	#relative_transform = skeleton.global_transform.affine_inverse() * skeleton.global_transform
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	target_node.global_position = hand_target.global_position
	#skeleton.set_bone_global_pose(hand_index, target_node.transform * hand_xform.transform)
	#hand_driver.set
	debug_draw.draw_line(skeleton.position + skeleton.get_bone_global_pose(hand_index).origin , Vector3(0,0,0))
	pass
