@tool
extends Node
class_name Yute

static func snap_force(initial:Vector2, direction:Vector2, delta:float, snappiness:float = 300, sharpness:float = 0.3) -> Vector2:
	return initial.move_toward(direction * sharpness / delta, snappiness) - initial #TODO refactor

# --- nodes ---

static func find_node_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child in root.get_children():
		var found = find_node_by_name(child, target_name)
		if found:
			return found
	return null

static func replace_node(current_node, new_node, parent):
	var index = parent.get_children().find(current_node)
	current_node.queue_free()
	if new_node:
		var n = new_node.instantiate()
		parent.add_child(n)
		parent.move_child(n, index)
		n.global_position = parent.global_position

static func get_ancestry(n: Node) -> Array[Node]:
	var out: Array[Node]
	var current = n
	while current:
		out.append(current)
		current = current.get_parent()
	out.reverse()
	return out

# --- random ---

static var rng = RandomNumberGenerator.new()
static func triangular_distribution(lower: float = -1.0, upper: float = 1.0) -> float:
	return rng.randf_range(upper, lower) + rng.randf_range(upper, lower)

static func percent_chance(i):
	return rng.randf() * 100 < i

static func cointoss() -> bool:
	return randf() < 0.5

static func randf_exp():
	return rng.randf() ** 2

static func pick_random_exp(a: Array):
	## each successive element is less likely to be picked
	return a[ int((randf_exp()) * a.size()) ]

static func vary(f: float, factor: float):
	return f + (randf() - 0.5) * f * factor

static func random_point(rect: Rect2, small: Rect2 = Rect2()) -> Vector2:
	## a uniformly random point inside `rect` where a `small` rect anchored at
	## that point (its `position`) still fits entirely inside `rect`
	var origin: Vector2 = rect.position
	var limit: Vector2 = rect.end - small.size
	limit.x = maxf(limit.x, origin.x)
	limit.y = maxf(limit.y, origin.y)
	return Vector2(
		rng.randf_range(origin.x, limit.x),
		rng.randf_range(origin.y, limit.y)
	)
