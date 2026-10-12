@tool
extends Node
class_name U2ls

# --- defaults, for static callers with no node in hand ---

static func _viewport(relative_to: Node = null) -> Viewport:
	if relative_to:
		return relative_to.get_viewport()
	return (Engine.get_main_loop() as SceneTree).root

static func _world(world: World2D = null) -> World2D:
	if world:
		return world
	return _viewport().get_world_2d()

# --- physics ---

enum {AREAS, BODIES, AREAS_AND_BODIES}
static func configure_query_parameters(pq: Object, mask, collider_type):
	pq.collide_with_areas = (collider_type == AREAS || collider_type == AREAS_AND_BODIES)
	pq.collide_with_bodies = (collider_type == BODIES || collider_type == AREAS_AND_BODIES)
	pq.collision_mask = Layers.physics2D[mask] if mask is String else mask

static func get_objects_at(where: Vector2, mask=65535, collider_type=AREAS_AND_BODIES, world: World2D=null) -> Array:
	var pq := PhysicsPointQueryParameters2D.new()
	configure_query_parameters(pq, mask, collider_type)
	pq.position = where
	return _world(world).direct_space_state.intersect_point(pq).map(func (d): return d.collider)

static func get_objects_under_body(what: Node2D, mask=65532, collider_type=AREAS_AND_BODIES, world: World2D=null) -> Array[Node2D]:
	var out: Array[Node2D]
	if what is CollisionObject2D:
		for c in what.get_children():
			if c is CollisionShape2D:
				for result in get_objects_under_body(c, mask, collider_type, world):
					out.append(result) # This code is not very wheelchair accessible
	elif what is CollisionShape2D and what.shape:
		var pq := PhysicsShapeQueryParameters2D.new()
		pq.shape = what.shape
		pq.transform = what.global_transform
		configure_query_parameters(pq, mask, collider_type)
		var result = _world(world).direct_space_state.intersect_shape(pq)
		for o in result:
			out.append(o.collider)
	return out

# --- coordinates ---

static func viewport_to_world(v: Vector2, relative_to: Node = null):
	var vp = _viewport(relative_to)
	return vp.global_canvas_transform.affine_inverse() * vp.canvas_transform.affine_inverse() * v

static func get_viewport_world_rect(relative_to: Node = null) -> Rect2:
	var r = _viewport(relative_to).get_visible_rect()
	var start = viewport_to_world(r.position, relative_to)
	var end = viewport_to_world(r.end, relative_to)
	return Rect2(start, end - start)

# --- rects ---

static func union_rect(a: Array[Rect2]) -> Rect2:
	if not a:
		return Rect2()

	var top_left = a[0].position
	var bottom_right = a[0].end
	for r in a:
		top_left.x = r.position.x if r.position.x < top_left.x else top_left.x
		top_left.y = r.position.y if r.position.y < top_left.y else top_left.y
		bottom_right.x = r.end.x if r.end.x > bottom_right.x else bottom_right.x
		bottom_right.y = r.end.y if r.end.y > bottom_right.y else bottom_right.y

	return Rect2(top_left, bottom_right - top_left)

static func four_corners(r: Rect2) -> Array[Vector2]:
	return [
		r.position,
		Vector2(r.position.x, r.end.y),
		r.end,
		Vector2(r.end.x, r.position.y)
	]

static func nearest(f: float, a: float, b: float):
	return a if abs(f-a) < abs(f-b) else b

static func get_nearest_point_on_perimeter(r: Rect2, p: Vector2):
	p.x =  clampf(p.x, r.position.x, r.end.x)
	p.y =  clampf(p.y, r.position.y, r.end.y)
	var nearest_x = nearest(p.x, r.position.x, r.end.x)
	var nearest_y = nearest(p.y, r.position.y, r.end.y)
	if abs(p.x - nearest_x) > abs(nearest_y - p.y):
		return Vector2(p.x, nearest_y)
	else:
		return Vector2(nearest_x, p.y)

static func nearest_overlapping_position(inner: Rect2, outer: Rect2) -> Vector2:
	if outer.encloses(inner):
		return inner.position

	# return inner's position plus the offset of the furthest vertex from outer
	var new_pos = four_corners(inner).filter(func(p):
		return not outer.has_point(p) #only outside points
	).map(func(v):
		return get_nearest_point_on_perimeter(outer, v) - v
	).reduce(func(v:Vector2, longest):
		return v if v.length_squared() > longest.length_squared() else longest
	) * 1.01 + inner.position

	if inner.size.x >= outer.size.x:
		new_pos.x = outer.position.x - (inner.size.x - outer.size.x) / 2
	if inner.size.y >= outer.size.y:
		new_pos.y = outer.position.y - (inner.size.y - outer.size.y) / 2

	#test that it works
	var new_inner = Rect2(new_pos, inner.size)
	assert(outer.encloses(new_inner) or inner.size.x >= outer.size.x or inner.size.y >= outer.size.y)

	return new_pos

static func globalise_rect(r: Rect2, rect_owner: Node2D):
	r.position *= rect_owner.global_scale
	r.position += rect_owner.global_position
	r.size *= rect_owner.global_scale
	return r

static func localise_rect(r: Rect2, rect_owner: Node2D):
	r.position -= rect_owner.global_position
	r.position /= rect_owner.global_scale
	r.size /= rect_owner.global_scale
	return r

static func get_global_rect(n: Node2D) -> Rect2:
	if not n:
		return Rect2()

	var s = n.get_script()
	if not Engine.is_editor_hint() or not s or s.is_tool():
		if n.has_method("get_global_rect"):
			return n.get_global_rect()
		if n.has_method("get_rect"):
			return globalise_rect(n.get_rect(), n)

	if n is CollisionShape2D and n.shape:
		return globalise_rect(n.shape.get_rect(), n)

	if n is CollisionObject2D:
		var shape_rects: Array[Rect2]
		for id in n.get_shape_owners():
			var offset = n.shape_owner_get_transform(id).origin
			for i in n.shape_owner_get_shape_count(id):
				var r = n.shape_owner_get_shape(id, i).get_rect()
				r.position += offset
				shape_rects.append(r)
		if shape_rects:
			return globalise_rect(union_rect(shape_rects), n)

	push_warning("Warn: get_global_rect: no support for object: %s" % n)
	return Rect2(n.global_position, Vector2.ZERO)

static func get_local_rect(n: Node2D) -> Rect2:
	return localise_rect(get_global_rect(n), n)

# --- canvas ---

static func get_canvas_item_global_z(node: CanvasItem) -> int:
	if not node.z_as_relative:
		return node.z_index
	var parent = node.get_parent()
	if parent is CanvasItem:
		return node.z_index + get_canvas_item_global_z(parent)
	return node.z_index
