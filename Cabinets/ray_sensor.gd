extends StaticBody3D
class_name RaySensor
## A sacrificial body mounted on an arcade screen, used as a raycast target for
## "lightgun" style input. Raycast against it, then query [method screen_uv] with
## the hit position (or use [method uv_from_hit] on the whole result).

var _verts: PackedVector3Array
var _uvs: PackedVector2Array
var _tris: PackedInt32Array

func _ready() -> void:
	_build_cache()

## Converts an intersection result (e.g. from
## [method PhysicsDirectSpaceState3D.intersect_ray]) into screen mesh UV coordinates
## (0..1), or [constant Vector2.INF] if the result's collider isn't a [RaySensor].
static func uv_from_hit(hit: Dictionary) -> Vector2:
	var collider: Node = hit.get("collider")
	if collider is RaySensor:
		return (collider as RaySensor).screen_uv(hit.get("position"))
	return Vector2.INF

## Returns the screen mesh UV (0..1) at [param world_point], or [constant Vector2.INF]
## if the point doesn't land on the screen.
func screen_uv(world_point: Vector3) -> Vector2:
	_build_cache()
	if _tris.is_empty():
		return Vector2.INF
	var mesh_parent := get_parent() as MeshInstance3D
	if mesh_parent == null:
		return Vector2.INF
	var local: Vector3 = mesh_parent.global_transform.affine_inverse() * world_point
	const EPS := 0.001
	for i in range(0, _tris.size(), 3):
		var a: Vector3 = _verts[_tris[i]]
		var b: Vector3 = _verts[_tris[i + 1]]
		var c: Vector3 = _verts[_tris[i + 2]]
		var bary := Geometry3D.get_triangle_barycentric_coords(local, a, b, c)
		if bary.x >= -EPS and bary.y >= -EPS and bary.z >= -EPS:
			return (
				_uvs[_tris[i]] * bary.x
				+ _uvs[_tris[i + 1]] * bary.y
				+ _uvs[_tris[i + 2]] * bary.z
			)
	return Vector2.INF

func _build_cache() -> void:
	if not _tris.is_empty():
		return
	var parent := get_parent()
	if parent is MeshInstance3D:
		var mesh: Mesh = (parent as MeshInstance3D).mesh
		if mesh and mesh.get_surface_count() > 0:
			var arrays := mesh.surface_get_arrays(0)
			_verts = arrays[Mesh.ARRAY_VERTEX]
			_uvs = arrays[Mesh.ARRAY_TEX_UV]
			_tris = arrays[Mesh.ARRAY_INDEX]