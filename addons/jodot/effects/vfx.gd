extends Object
class_name VFX

# --- Static Part ---

static var effects: Dictionary[StringName,Array]: # Array[Subframes]
	get():
		if not effects:
			effects = build_effects_table(
				preload("res://addons/jodot/effects/vfx.png"),
				preload("res://addons/jodot/effects/vfx.json"),
			)
		return effects
static var pool=Pool.new(preload("res://addons/jodot/effects/v_effect.tscn"), 16)

class Subframes:
	var spritesheet:Texture2D
	var start: int
	var end: int
	var rate: int
	var label: StringName
	func _init(spritesheet, start, end, rate, label):
		self.spritesheet = spritesheet
		self.start = start
		self.end = end
		self.rate = rate
		self.label = label

static func build_effects_table(spritesheet:Texture2D, spritesheet_json:Object) -> Dictionary[StringName, Array]:
	var out:Dictionary[StringName, Array]
	var r = RegEx.new()
	r.compile("[^0-9]+")
	for tag in spritesheet_json.data.meta.frameTags:
		var k = r.search(tag.name).get_string()
		var v = Subframes.new(
			spritesheet,
			int(tag.from),
			int(tag.to),
			tag.data if tag.has("data") else 20,
			tag.name
		)
		if out.has(k):
			if k != tag.name: # contains numbers and is therefore part of a group
					assert(out[k] is Array)
					out[k].append(v)
			else:
				print("warn: key clash in vfx table: ",k)
		else:
			out[k] = [v]
	print("built vfx table:\n%s" % out)
	return out

static func acquire(at:Node, offset: Vector2=Vector2.ZERO) -> VFXSprite:
	var vs: VFXSprite = pool.next(null)
	assert(vs)
	assert(at and is_instance_valid(at))
	vs.position = offset
	at.add_child(vs)
	#vs.reset_physics_interpolation()
	return vs

static func get_animation(id: StringName) -> Subframes:
	return effects[id].pick_random()

static func play(id: StringName, at:Node, offset: Vector2=Vector2.ZERO) -> VFXSprite:
	var vs:VFXSprite = acquire(at, offset)
	vs.play(get_animation(id))
	return vs


static func play_looping(id: StringName, at:Node, offset: Vector2=Vector2.ZERO) -> VFXSprite:
	var vs:VFXSprite = acquire(at, offset)
	vs.play(get_animation(id), -1)
	return vs
