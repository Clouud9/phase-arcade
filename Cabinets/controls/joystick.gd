extends Node3D

@export var stick:NodePath
@onready var _stick:Node3D = get_node(stick)

## Fraction of [code]travel[/code] to ignore when testing for the edge. Analogue
## sticks rarely reach their full range, so count a deflection as hitting the
## edge once it gets within this margin of max travel.
@export_range(0.0, 0.9, 0.01) var edge_threshold := 0.1

const REST_EPS := 0.001
const MIN_LOUDNESS := 0.0001

@onready var _edge_base_db:float = $EdgeSFX.volume_db
@onready var _rest_base_db:float = $RestSFX.volume_db

var _at_edge := false
var _at_rest := true
var _speed_from_centre := 0.0

func deflect(v:Vector2, delta:float, travel:float=0.3, speed:float=10):
	var before := _stick.rotation
	_stick.rotation = _stick.rotation.move_toward(Vector3(v.y, 0, -v.x) * travel, speed * delta)

	# Signed speed from the centre: + when striking outward toward the edge,
	# - when springing back toward the neutral position. Only the radial
	# component counts, so sliding between gates stays quiet.
	var radial := (_stick.rotation.length() - before.length()) / delta
	if radial > 0.0:
		_speed_from_centre = maxf(_speed_from_centre, radial) if _speed_from_centre > 0.0 else radial
	elif radial < 0.0:
		_speed_from_centre = minf(_speed_from_centre, radial) if _speed_from_centre < 0.0 else radial

	var len := _stick.rotation.length()
	var at_edge := len >= travel * (1.0 - edge_threshold)
	var at_rest := len <= REST_EPS
	var loudness := clampf(absf(_speed_from_centre) / speed, MIN_LOUDNESS, 1.0)

	if at_edge and not _at_edge and _speed_from_centre > 0.0:
		_play($EdgeSFX, _edge_base_db, loudness)
	if at_rest and not _at_rest and _speed_from_centre < 0.0:
		_play($RestSFX, _rest_base_db, loudness)

	_at_edge = at_edge
	_at_rest = at_rest

func _play(player:AudioStreamPlayer3D, base_db:float, loudness:float) -> void:
	player.volume_db = base_db + linear_to_db(loudness)
	player.play()
