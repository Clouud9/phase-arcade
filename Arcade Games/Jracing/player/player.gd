extends RigidBody2D
class_name JracingPlayer

var direction: float
var controller: PlayerController
var vehicle_data: VehicleData
var index: int
var player_name: String = ""
var damage_sound: Node = null

var is_ready: bool = true
var finish_time: float = 0
var lap: int = 0
var lap_progress: float = -1
var previous_position: Vector2
var hit_normal: Vector2 = Vector2.ZERO
var update_direction: bool = true
var sprite_state: int = 0
var can_be_seen: bool = true

func _physics_process(_delta: float) -> void:
	if RaceManager.instance.time >= 0:
		controller.tick()
	hit_normal = Vector2.ZERO
	var new_lap_progress := RaceManager.instance.lap_progress(global_position)
	if lap_progress >= 0:
		if new_lap_progress < 1 and lap_progress > 2:
			if (
				lap == RaceManager.track_data.laps and
				controller is not PlayerController.RemotePlayerController
			):
				var polygon := RaceManager.instance.track.polygon
				var line_forward := (polygon[1] - polygon[0]).normalized()
				var distance_passed := maxf(0, line_forward.dot(global_position - polygon[0]))
				var distance_before := maxf(0, -line_forward.dot(previous_position - polygon[0]))
				if is_zero_approx(distance_before + distance_passed):
					distance_before = INF
				finish_time = (
					RaceManager.instance.time - distance_passed / (distance_before + distance_passed))
				controller.handle_finish()
					
			lap += 1
		elif new_lap_progress > 2 and lap_progress < 1:
			lap -= 1
	lap_progress = new_lap_progress
	previous_position = global_position

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		hit_normal = state.get_contact_local_normal(0)

func ahead_of(opponent: JracingPlayer) -> bool:
	if finish_time == INF: return false
	if opponent.finish_time == INF: return true
	if is_done(): return not opponent.is_done() or finish_time < opponent.finish_time
	if lap != opponent.lap: return lap > opponent.lap
	return lap_progress > opponent.lap_progress

func is_done() -> bool:
	return finish_time != 0

func play_damage_sound() -> void:
	damage_sound.call("play")
