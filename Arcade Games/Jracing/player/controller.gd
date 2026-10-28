class_name PlayerController

var player: JracingPlayer

func tick() -> void: pass
func take(_packet: PackedByteArray, _start: int) -> void: pass
func take_json(_packet: Dictionary) -> void: pass
func boost() -> void: pass

func handle_finish() -> void:
	var ctrl := CPUPlayerController.new()
	ctrl.player = player
	ctrl.ai_data.straight_weight = 3
	player.controller = ctrl

class NetworkTickState:
	var tick: int
	var position: Vector2
	var direction: float
	var spinout: int = 0

class RemotePlayerController extends PlayerController:
	var tm1: NetworkTickState
	var tm0: NetworkTickState
	
	func _init() -> void:
		tm1 = NetworkTickState.new()
		tm1.tick = -2
		tm0 = NetworkTickState.new()
		tm0.tick = -1
	
	func tick() -> void:
		if tm1.tick < 0:
			tm1.position = player.global_position
			tm1.direction = player.direction
			tm0.position = player.global_position
			tm0.direction = player.direction
			player.collision_mask = 0
			
		var t := minf(5, inverse_lerp(tm1.tick, tm0.tick, RaceManager.instance.time))
		player.global_position = player.global_position.move_toward(
			tm1.position.lerp(tm0.position, t),
			player.vehicle_data.max_speed / 30
		)
		player.direction = lerp_angle(tm1.direction, tm0.direction, t)
		
		if RaceManager.instance.time < tm0.tick + tm0.spinout:
			player.sprite_state = 0
		else:
			player.sprite_state = 3
	
	func take(packet: PackedByteArray, start: int) -> void:
		var new := tm1
		tm1 = tm0
		
		new.tick = packet[start + 1] + 256 * packet[start + 2] + 65536 * packet[start + 3]
		new.direction = packet[start + 4] * (PI / 128)
		new.position = Vector2(
			packet.decode_u16(start + 5) - 32768,
			packet.decode_u16(start + 7) - 32768
		)
		new.spinout = packet[start + 9]
		
		tm0 = new
		
		if tm0.spinout > tm1.spinout:
			player.play_damage_sound()
	
	func take_json(packet: Dictionary) -> void:
		var act: String = packet["act"]
		if act == "name":
			player.player_name = packet["name"]
		elif act == "ready":
			player.is_ready = true
		elif act == "goal":
			player.finish_time = packet["time"]
			handle_finish()
		elif act == "disconnect":
			player.is_ready = true
			player.finish_time = INF
			player.controller = PlayerController.new()

class DriverControlState:
	var accelerate: bool
	var brake: bool
	var steer: float
	
	func clone() -> DriverControlState:
		var new := DriverControlState.new()
		new.accelerate = accelerate
		new.brake = brake
		new.steer = steer
		return new

class DriverState:
	var space: PhysicsDirectSpaceState2D
	var tilemap: TileMapLayer = null
	var vehicle_data: VehicleData
	var steer: float = 0
	var direction: float
	var position: Vector2
	var velocity: Vector2
	var crashed: bool = false
	var spinout: int = 0
	var boost: bool = false
	
	func clone() -> DriverState:
		var new := DriverState.new()
		new.space = space
		new.tilemap = tilemap
		new.vehicle_data = vehicle_data
		new.steer = steer
		new.direction = direction
		new.position = position
		new.velocity = velocity
		new.boost = boost
		return new
	
	func handle_controls(controls: DriverControlState) -> Vector2:
		var rel_velocity := velocity.rotated(-direction)
		var target_speed := rel_velocity.x * 0.995
		
		if rel_velocity.x < vehicle_data.max_speed:
			boost = false
			
		if controls.accelerate:
			target_speed = vehicle_data.max_speed
			if controls.brake:
				target_speed *= 0.5
			elif boost:
				target_speed = maxf(target_speed, rel_velocity.x)
		elif controls.brake:
			target_speed = 0
		
		if tilemap != null:
			var tile_pos := tilemap.local_to_map(position)
			var tile_data := tilemap.get_cell_tile_data(tile_pos)
			if tile_data and tile_data.has_custom_data("speed_modifier"):
				var speed_mod: float = tile_data.get_custom_data("speed_modifier")
				if speed_mod > 0.0 and speed_mod < 1.0:
					target_speed *= speed_mod
		
		var acceleration := vehicle_data.acceleration
		if target_speed < rel_velocity.x:
			acceleration = vehicle_data.braking
		
		var force := Vector2(
			signf(target_speed - rel_velocity.x) * minf(
				acceleration,
				absf(target_speed - rel_velocity.x) * 60
			),
			rel_velocity.y / -(vehicle_data.slip + 1.0/60)
		).rotated(direction)
		
		steer = lerpf(steer, controls.steer, 0.3)
		direction += steer * vehicle_data.turning
		
		return force
	
	func simulate_ticks(collider_rid: RID, ticks: int) -> void:
		if crashed: return
		var query := PhysicsShapeQueryParameters2D.new()
		var movement := velocity / 60 * ticks
		query.shape_rid = collider_rid
		query.motion = movement
		query.transform = query.transform.translated(position)
		query.collision_mask = 1
		crashed = space.cast_motion(query)[0] < 1
		position += movement

@abstract
class DrivenPlayerController extends PlayerController:
	var state: DriverState
	var engine: AudioStreamPlayer = null
	
	func _init() -> void:
		state = DriverState.new()
	
	func boost() -> void:
		if state.spinout == 0:
			state.boost = true
			player.linear_velocity = (
				Vector2.RIGHT.rotated(state.direction) * (player.vehicle_data.max_speed * 1.5))
	
	func tick() -> void:
		if state.space == null:
			state.space = player.get_world_2d().direct_space_state
			state.tilemap = RaceManager.instance.track.get_child(0) as TileMapLayer
			state.vehicle_data = player.vehicle_data
			
		if player.damage_sound is AudioStreamPlayer:
			if engine == null:
				engine = player.find_child("Engine")
				if OS.get_name() == "Web":
					engine.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
			
			var tmax: float = 1
			if state.boost:
				tmax = 2
			var t: float = clampf(
				Vector2.RIGHT.rotated(state.direction).dot(player.linear_velocity) /
				player.vehicle_data.max_speed * 1.05,
				0.25,
				tmax
			)
			engine.volume_linear = t
			engine.pitch_scale = t
			var going: bool = player.sprite_state != 0 and t > 0.25
			if engine.playing and not going:
				engine.stop()
			elif not engine.playing and going:
				engine.play()
			
		if not player.hit_normal.is_zero_approx() and (
			player.can_be_seen or
			player.linear_velocity.length_squared() <
			player.vehicle_data.max_speed * player.vehicle_data.max_speed * 0.2
		):
			player.linear_velocity = player.hit_normal * 200
			player.update_direction = false
			if state.spinout == 0:
				state.spinout = 60
				player.play_damage_sound()
				
		if state.spinout > 0:
			state.spinout -= 1
			player.apply_central_force(player.linear_velocity.normalized() * -100)
			if state.spinout == 0:
				player.direction = state.direction
				player.update_direction = true
			else:
				player.direction += 0.1
			player.sprite_state = 0
			return
			
		state.direction = player.direction
		state.position = player.global_position
		state.velocity = player.linear_velocity
		var controls := get_controls()
		
		player.apply_central_force(state.handle_controls(controls))
		
		player.direction = state.direction
		if not controls.accelerate:
			player.sprite_state = 0
		elif (state.velocity.length_squared() <
			player.vehicle_data.max_speed * player.vehicle_data.max_speed * 0.7):
			player.sprite_state = 1
		elif (state.velocity.length_squared() <
			player.vehicle_data.max_speed*player.vehicle_data.max_speed * 0.95 and not controls.brake):
			player.sprite_state = 2
		else:
			player.sprite_state = 3
		
	@abstract
	func get_controls() -> DriverControlState

class LocalInputPlayerController extends DrivenPlayerController:
	var network_packet: PackedByteArray
	
	func tick() -> void:
		super()
			
		if (
			RaceManager.network_connection != null and
			RaceManager.instance.time % RaceManager.network_update_frequency ==
			RaceManager.network_update_frequency - 1 and
			RaceManager.network_connection.get_ready_state() == WebSocketPeer.State.STATE_OPEN
		):
			if len(network_packet) == 0:
				network_packet = PackedByteArray([player.index, 0,0,0, 0, 0,0, 0,0, 0])
			network_packet[1] = RaceManager.instance.time
			network_packet[2] = RaceManager.instance.time >> 8
			network_packet[3] = RaceManager.instance.time >> 16
			network_packet[4] = int(player.direction * (128/PI))
			network_packet.encode_u16(5, int(player.global_position.x) + 32768)
			network_packet.encode_u16(7, int(player.global_position.y) + 32768)
			network_packet[9] = state.spinout
			RaceManager.network_connection.send(network_packet)
	
	func handle_finish() -> void:
		RaceManager.instance.on_local_player_finish(player)
		super()
	
	func get_controls() -> DriverControlState:
		var input := DriverControlState.new()
		input.accelerate = Input.is_action_pressed("accelerate")
		input.brake = Input.is_action_pressed("brake")
		input.steer = Input.get_axis("ui_left", "ui_right")
		
		return input

class AIData:
	var forwards_weight: float
	var inside_weight: float
	var inside_amount: float
	var straight_weight: float
	
	func randomise() -> void:
		forwards_weight = randf() * 20
		inside_weight = randf() / 2
		inside_amount = randf_range(-48, 48)
		straight_weight = randf() * 3

class CPUPlayerController extends DrivenPlayerController:
	var cache: DriverControlState
	var cache_timeout: int = -1
	var try: Array[DriverControlState]
	var shape_rid: RID
	var ai_data: AIData
	
	func _init() -> void:
		super()
		shape_rid = PhysicsServer2D.circle_shape_create()
		PhysicsServer2D.shape_set_data(shape_rid, 1.04)
		try = []
		for i in range(-2, 3):
			var dcs := DriverControlState.new()
			dcs.steer = i / 2.0
			dcs.accelerate = true
			try.append(dcs)
			if i != 0:
				dcs = dcs.clone()
				dcs.brake = true
				try.append(dcs)
		cache = try[4]
		ai_data = AIData.new()
		ai_data.randomise()
	
	func handle_finish() -> void: pass
		
	func get_controls() -> DriverControlState:
		if cache_timeout < 0:
			cache_timeout = player.index
		if cache_timeout == 0:
			cache_timeout = 8
			var best: float = -INF
			for dcs in try:
				var score := get_score(dcs)
				if score > best:
					best = score
					cache = dcs
		else:
			cache_timeout -= 1
		return cache
	
	func get_score(dcs: DriverControlState) -> float:
		var test_state := state.clone()
		var crashed: bool = false
		for i in range(15):
			for j in range(2):
				test_state.velocity += test_state.handle_controls(dcs) / 60
			test_state.simulate_ticks(shape_rid, 2)
			#if test_state.crashed:
			#	break
			if i > 8:
				crashed = test_state.crashed
				if dcs.brake:
					dcs = dcs.clone()
					dcs.brake = false
		var progress := RaceManager.instance.lap_progress(test_state.position)
		if progress < 1 and player.lap_progress > 2:
			progress += ceilf(player.lap_progress)
		if progress > player.lap_progress + 1.5:
			return -1
		if crashed:
			progress = lerpf(progress, player.lap_progress, 0.5) - 1
		var pi := progress as int
		if pi < len(RaceManager.instance.track.polygon) and not test_state.crashed:
			var target_forwards := (
				RaceManager.instance.track.polygon[(pi + 1) % len(RaceManager.instance.track.polygon)] -
				RaceManager.instance.track.polygon[pi]
			)
			var segment_length := target_forwards.length()
			target_forwards = target_forwards.normalized()
			var forwards := Vector2.RIGHT.rotated(test_state.direction)
			progress += forwards.dot(target_forwards) * ai_data.forwards_weight / segment_length
			progress -= absf((
				RaceManager.instance.track.polygon[(pi + 2) % len(RaceManager.instance.track.polygon)] -
				RaceManager.instance.track.polygon[(pi + 1) % len(RaceManager.instance.track.polygon)]
			).normalized().dot(
				(
					test_state.position -
					RaceManager.instance.track.polygon[(pi + 1) % len(RaceManager.instance.track.polygon)]
				)
			) - ai_data.inside_amount) * ai_data.inside_weight / segment_length
			if dcs.steer != 0:
				progress -= ai_data.straight_weight / segment_length
		return progress
