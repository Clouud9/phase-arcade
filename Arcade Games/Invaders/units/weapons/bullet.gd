extends Unit
class_name Bullet

@export var payload: PackedScene

func _expire():
	if not alive:
		return
	if payload_instance:
		if payload_instance is Unit:
			payload_instance.collision_mask = collision_mask
		if payload_instance is Node2D:
			(payload_instance as Node2D).global_position = global_position
		InvadersGame.add_to_playfield(payload_instance, self)
		if payload_instance is Shoota:
			payload_instance.shoot(direction, null, collision_mask)
	super()

var payload_instance: Node
func _ready():
	if payload:
		payload_instance = payload.instantiate()
		if "points_claimed" in payload_instance and payload_instance.points_claimed is Signal:
			payload_instance.points_claimed.connect(claim_points)
	super()

func wakeup():
	super()
	if is_on_enemy_team():
		$Sprite2D.evil_mode = true
