@tool
class_name Layers

const CATEGORIES: Array[StringName] = [
	"2d_physics",
	"2d_render",
	"3d_physics",
	"3d_render",
]

static var _maps: Dictionary[StringName, Dictionary] = {}

static func map(category: StringName) -> Dictionary[String, int]:
	if not CATEGORIES.has(category):
		push_error("Layers.map: unknown category '%s'" % category)
		return {}
	if not _maps.has(category):
		var layers: Dictionary[String, int] = {}
		for i in range(1, 33):
			var layer_name: String = ProjectSettings.get_setting(
				"layer_names/%s/layer_%d" % [category, i], "")
			if layer_name:
				layers[layer_name] = 1 << (i - 1)
		_maps[category] = layers
		print("Generated layer map for %s:" % category, layers)
	return _maps[category]

static var physics2D: Dictionary[String, int]:
	get:
		return map("2d_physics")

static var render2D: Dictionary[String, int]:
	get:
		return map("2d_render")

static var physics3D: Dictionary[String, int]:
	get:
		return map("3d_physics")

static var render3D: Dictionary[String, int]:
	get:
		return map("3d_render")

static func combined(category:StringName, layer_names:Array[String], ) -> int:
	var out := 0
	for s in layer_names:
		out |= map(category)[s]
	return out

static func separate(category:StringName, mask: int,) -> Array[String]:
	var out: Array[String]
	for k in map(category):
		if mask & map(category)[k]:
			out.append(k)
	return out
