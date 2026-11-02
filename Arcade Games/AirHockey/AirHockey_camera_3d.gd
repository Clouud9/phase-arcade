extends Camera3D
@onready var debug_draw: DebugDraw3D = $DebugDraw3D

signal round_active(round_over:bool, player_score:int, opponent_score:int)

@export var player_mallet:CharacterBody3D
@export var opp_mallet:Node3D
@export var puck:RigidBody3D
@export var goal_player:Area3D
@export var goal_opp:Area3D
@export var scoreboard_player:MeshInstance3D
@export var scoreboard_opp:MeshInstance3D
#var player_mallet_collision:CharacterBody3D
var round_over:bool
var round_over_time:float = 2.5
var score_player:int = 0
var score_opp:int = 0
var ray_query = PhysicsRayQueryParameters3D.new()
var query_result:Vector3
var player_next_position:Vector3
var max_collisions:float = 3
var charge_shot:bool = false
var charge_timer:float
var charge_start:Vector3
var player_bounds_min = Vector3(-.5, 0, -1.07)
var player_bounds_max = Vector3(.5, 0, 0)
var opp_acceleration:float = 0.01
var opp_movement:float = 0
var opp_target:float = 0
var opp_error:float = 0
var opp_error_last:float = 0
var opp_PID_p:float = 0.1
var opp_PID_i:float = 0.1
var opp_PID_integration:float = 0
var puck_stuck_timer:float = 0
var reset_position:Vector3 = Vector3(0,0.5,0)
var sfx_goal: AudioStreamPlayer3D
var sfx_hit: AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var player_mallet_collision:RigidBody3D = player_mallet.find_child("RigidBody3D")
	var ignored: Array[RID] = []
	ignored.append(player_mallet.get_rid())
	ray_query.exclude = ignored
	sfx_goal = puck.find_child("SFX_Goal")
	sfx_hit = puck.find_child("SFX_Hit")
	round_over = false
	await get_tree().create_timer(0.0).timeout
	emit_signal('round_active', false)#0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	query_result = raycast_mouse()
	if charge_shot:
		charge_timer += delta
		if query_result.distance_to(player_mallet.position) > 0.1:
			print("pinpan")
			charge_shot = false
			charge_timer = 0
			pass
	else:
		#player_mallet.position = player_next_position
		player_next_position = query_result
		var impact_speed = player_next_position - player_mallet.position
		player_next_position = player_next_position.clamp(player_bounds_min, player_bounds_max)
		var player_next_offset = player_next_position - player_mallet.position#this doesn't work, it's the offset. clamping the movement *delta*.
		
		#player_mallet.velocity = player_next_offset/delta
		max_collisions = 3
		player_move(player_next_offset, impact_speed, delta)

		#player_mallet.position = player_mallet.position.clamp(player_bounds_min, player_bounds_max)
		if puck in goal_player.get_overlapping_bodies():
			score(goal_player)
		elif puck in goal_opp.get_overlapping_bodies():
			score(goal_opp)
		
	opponent_ai(delta)
	if !round_over:
		if puck.position.y < -4 || puck.position.y > 10:
			print("PUCK OUT OF BOUNDS")
			reset_puck()
		if puck.linear_velocity.length() < 0.1:
			puck_stuck_timer += delta
		elif puck.linear_velocity.length() > 0.5 && puck.position.z < -0.1:
			puck_stuck_timer = 0
		if puck_stuck_timer > 5.0:
			print("PUCK TIMEOUT")
			reset_puck()
		elif puck_stuck_timer > 2.0:
			if puck.linear_velocity.length() < 0.5 && puck.position.z > -0.1 :
				puck.apply_force(Vector3(0,0,-2.0))
	pass

func _input(event):
	if event.is_action_pressed("interact"):
		charge_shot = true
		charge_timer = 0.01
		charge_start = player_mallet.position
	if event.is_action_pressed("fire"):
		Engine.time_scale = .3
	if event.is_action_released("fire"):
		Engine.time_scale = 1.0
		
	pass

func reset_puck():
	puck_stuck_timer = 0
	puck.position = reset_position
	puck.linear_velocity = Vector3(0,0.1,0)
	round_over = false
	emit_signal('round_active', false)#0)#score_opp, score_player)
	pass

func raycast_mouse() -> Vector3:
	var mouse_position = get_viewport().get_mouse_position()
	var ray_length = 5
	var from = project_ray_origin(mouse_position)
	var to = from + project_ray_normal(mouse_position) * ray_length
	var space = get_world_3d().direct_space_state
	ray_query.from = from
	ray_query.to = to
	#ray_query.collide_with_bodies.
	var raycast_result = space.intersect_ray(ray_query)
	
	if !raycast_result.is_empty():
		return raycast_result["position"]
	return player_mallet.position
	
func player_move(target_offset:Vector3, from:Vector3, delta:float):
	if max_collisions > 0:
		max_collisions -= 1
		var hit:KinematicCollision3D = player_mallet.move_and_collide(target_offset)
		if hit != null:
			if hit.get_collider() == puck:
				#puck.apply_force((1.5 * impact_speed) / delta)
				#puck.apply_impulse((puck.position - player_mallet.position).normalized() * .40)
				var lookat:Vector3 = (puck.position - player_mallet.position) * Vector3(1,0,1)
				#var lookat:Vector3 = (player_mallet.position - puck.position ) * Vector3(1,0,1)
				var debug_point = puck.position + Vector3(0, 0.1, 0)
				
				#debug_draw.draw_line(debug_point, debug_point - puck.linear_velocity, Color(1,0,0,1), 2)
				
				if lookat.normalized().dot(puck.linear_velocity.normalized()) < 0:
					puck.linear_velocity = puck.linear_velocity.bounce(lookat.normalized())
					puck.linear_velocity += target_offset
					
				#puck.linear_velocity = puck.linear_velocity.bounce(lookat.normalized())
				debug_draw.draw_line(debug_point, debug_point + lookat.normalized(), Color(0,0,1,1), 2)
				debug_draw.draw_line(debug_point, debug_point + puck.linear_velocity, Color(1,1,0,1), 2)
				#puck.linear_velocity = puck.linear_velocity.bounce(lookat.normalized())
				puck.apply_force((1.5 * from) / delta)
				sfx_hit.play()
			else:
				var reflected_target = hit.get_remainder().bounce(hit.get_normal())
				var real_position = clamp(player_mallet.position + hit.get_remainder(), player_bounds_min, player_bounds_max)
				player_mallet.position = player_mallet.position + hit.get_remainder().bounce(hit.get_normal())
				
				player_move(hit.get_normal() * hit.get_remainder().length() * -1, player_mallet.position, delta)

func player_move_slide(target_offset:Vector3, from:Vector3, delta:float):
		var hit:KinematicCollision3D = player_mallet.move_and_collide(target_offset)
		if hit != null:
			if hit.get_collider() == puck:
				#puck.apply_impulse((puck.position - player_mallet.position).normalized() * .40)
				var lookat:Vector3 = (puck.position - player_mallet.position) * Vector3(1,0,1)
				var debug_point = puck.position + Vector3(0, 0.3, 0)
				debug_draw.draw_arrow(debug_point, puck.linear_velocity, Color(1,0,0,1))
				puck.linear_velocity = puck.linear_velocity.bounce(lookat.normalized())
				debug_draw.draw_arrow(debug_point, lookat.normalized(), Color(0,0,1,1))
				debug_draw.draw_arrow(debug_point, puck.linear_velocity, Color(1,1,0,1))
				puck.apply_force((1.5 * from) / delta)
				sfx_hit.play()
			else:
				var reflected_target = target_offset.bounce(hit.get_normal()).normalized() * (target_offset.length() / (from - player_mallet.position).length())
				player_move(reflected_target, player_mallet.position, delta)
	
func opponent_ai(delta: float):
	#var target_pos:Vector3 = 
	if !round_over:
		if puck.position.z < opp_mallet.position.z:
			#opp_error = puck.position.x - opp_mallet.position.x #very dumb "get laterally in front"
			#var puck_intersect:float = lerpf(0, puck.position.x, puck.position.z/1.1)#this might even be worse, it's basically a scaled down version of the above.
			var puck_intersect:float = lerpf(0, puck.position.x, clampf(puck.position.z/.68, 0.3, 1))#dividing by 1.1 wasn't necessary, the mallet's at .68
			
			opp_error = puck_intersect - opp_mallet.position.x
		else:
			opp_error = (-0.2 * puck.position.x) - opp_mallet.position.x 
	else:
		opp_error = -opp_mallet.position.x
		
	
	
	var P = opp_error * opp_PID_p
	
	opp_PID_integration = clamp(opp_PID_integration + (opp_error * delta), -opp_PID_i, opp_PID_i)
	var I = opp_PID_i * opp_PID_integration
	opp_movement = clampf(P + I, -0.1,0.1)
	opp_target = clampf(opp_target + opp_movement, -.5,.5)
	opp_mallet.position.x = opp_target
	opp_mallet.position.z = lerpf(opp_mallet.position.z, clampf(puck.position.z+0.08, 0.5, .8), clampf(delta * 10, 0, 1))
	
	if opp_mallet.position.distance_to(puck.position) < 0.1: # abs(opp_mallet.position.x - puck.position.x) < 0.15 && opp_mallet.position.z > puck.position.z && puck.position.z > 0.6:
		puck.apply_impulse((puck.position - opp_mallet.position).normalized() * 1.0)
	pass

func score(goal:Area3D):
	if !round_over:
		round_over = true
		puck.position = Vector3(0,-3,0)
		sfx_goal.play()
		if goal == goal_opp:
			score_player += 1
			scoreboard_player.get_active_material(0).set("shader_parameter/DisplayDigit", score_player)
		elif goal == goal_player:
			score_opp += 1
			scoreboard_opp.get_active_material(0).set("shader_parameter/DisplayDigit", score_opp)
		emit_signal('round_active', true, score_opp, score_player)
		await get_tree().create_timer(round_over_time).timeout
		reset_puck()
	pass
