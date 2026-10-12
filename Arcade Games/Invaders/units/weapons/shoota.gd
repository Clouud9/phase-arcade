extends Node2D
class_name Shoota

@export var ammo: PackedScene
@export_range(1,64,1) var ammo_count = 3
@export var pool_mode: Pool.Poolmode = Pool.Poolmode.PASS
@export_range(0.0, 10.0) var interval = 0.0
@export_range(0, 360, 1, "radians_as_degrees") var spread: float = 0
@export var apply_impulse: float = 0
@export var autoshoot = false:
	set(b):
		if autoshoot != b:
			_autoshoot_changed(bool(b))
		autoshoot = b
@export var oneshot = false
@export var default_direction = Vector2.UP
@export var shoot_fx: Array[FXID]
@export_range(0,1) var run_and_gun: float = 1
@export var run_and_gun_envelope: Envelope
@export var windup_time = 0.0
@export var windup_sfx = ""
@export var windup_sfx_envelope: Envelope

signal points_claimed(int)

signal windup_started
signal windup_ended(bool)
signal cooled_down

var bullet_pool: Pool
var parent: Unit

signal autoshoot_enabled
signal autoshoot_disabled
func _autoshoot_changed(state: bool):
	if state:
		autoshoot_enabled.emit()
		active_time = 0.0 #NOTE: this allows cancelling rag release. IDK how to fix this
	else:
		autoshoot_disabled.emit()
		winding_up = false

func get_speed_modifier() -> float:
	if run_and_gun_envelope:
		return 1.0 - run_and_gun_envelope.value(active_time, inactive_time)
	return run_and_gun if autoshoot or winding_up else 1.0

func find_first_node_not_under_unit() -> Node:
	var ancestry = Yute.get_ancestry(self)
	var candidate: Node = null
	for n in ancestry:
		if n is Unit or n is FauxUnit:
			return candidate
		candidate = n
	return candidate

func resolve_direction(towards:Variant) -> Vector2:
	if towards is Vector2:
		return towards.normalized()
	elif towards is Node2D:
		return (towards.global_position - global_position).normalized()
	assert(false)
	return default_direction

var windup_sfx_control: SFXPlayer.SFXControl
var winding_up = false
func windup():
	windup_countdown = windup_time
	if windup_sfx and windup_countdown:
		windup_sfx_control = Game.play_sfx(self,windup_sfx)
	winding_up = true
	windup_started.emit()

func shoot(towards:Variant = default_direction, parent_to:Node=null, mask:int=-1) -> Unit:
	if cooldown_countdown > 0:
		return null
	windup()
	if windup_countdown > 0:
		var status = await windup_ended #pls no race condition
		if windup_sfx_control:
			windup_sfx_control.stop()
			windup_sfx_control = null
		if not status:
			return null

	var direction = resolve_direction(towards)

	if mask == -1:
		mask = Layers.combined("2d_physics", ["World", "Friendly", "Enemy"])
		if parent:
			if not parent.is_node_ready():
				await parent.ready
			mask &= ~get_parent().collision_layer # don't collide with parent

	var bullet: Unit = bullet_pool.next(null)
	if bullet:
		assert(bullet is Unit)
		bullet.collision_mask = mask
		bullet.direction = direction.normalized().rotated((randf() - 0.5) * spread)
		bullet.velocity += bullet.direction * apply_impulse
		if not bullet.points_claimed.is_connected(points_claimed.emit):
			bullet.points_claimed.connect(points_claimed.emit)
		for fx in shoot_fx:
			fx.play(self)

		var game = Game.get_game(self)
		if game:
			InvadersGame.add_to_playfield(bullet, parent_to if parent_to else self)
		else:
			bullet = bullet_pool.next(find_first_node_not_under_unit())
		bullet.wakeup()

		if oneshot:
			autoshoot_in_loop = false
		cooldown_countdown = interval

	return bullet

var windup_countdown: float
var cooldown_countdown: float
var active_time: float
var inactive_time: float
var autoshoot_in_loop = true
func _process(delta):
	if cooldown_countdown > 0:
		cooldown_countdown -= delta
		if cooldown_countdown <= 0:
			cooled_down.emit()
	elif windup_countdown > 0:
		if winding_up:
			windup_countdown -= delta
			if windup_countdown <= 0:
				windup_ended.emit(true)
		else:
			windup_ended.emit(false) #windup cancelled
			windup_countdown = 0
	elif autoshoot and autoshoot_in_loop:
		shoot()

	if autoshoot or winding_up:
		active_time += delta
		inactive_time = 0.0
	else:
		inactive_time += delta

func _ready():
	if ammo:
		bullet_pool = Pool.new(ammo, ammo_count, pool_mode, true, false)
	if not interval:
		oneshot = true
	if get_parent() and get_parent() is Unit:
		parent = get_parent()
