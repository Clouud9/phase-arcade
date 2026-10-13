extends Game
class_name InvadersGame

@export var play_area: PlayArea
@export var new_entity_region: Node2D
@export var lives: Lives
@export var current_player: Player
@export var player_spawn_point: Marker2D
@export var dialgoue_screens: Array[DialogueScreen]
@export var waves: Array[PackedScene]
@export var wave: int = 0

func _on_player_died():
	if not lives:
		return lose()

	await Utils.delay(1)
	var next_life = lives.get_life()
	if not next_life:
		return lose()
	spawn_player(next_life)
	set_active_player(next_life)

func spawn_player(p: Player):
	if player_spawn_point:
		add_to_playfield(p, player_spawn_point)
	else:
		new_entity_region.add_child(p)
	p.wakeup() # TODO maybe this should always be triggered manually?

signal player_changed(Player)
func set_active_player(p: Player):
	current_player = p
	if not p.expire.is_connected(_on_player_died):
		p.expire.connect(_on_player_died)
	player_changed.emit(p)

func on_beat_wave():
	win()

func spawn_wave(w: PackedScene):
	var n = w.instantiate()
	await add_to_playfield(n, self)
	n.expire.connect(on_beat_wave)
	n.start()

static func add_to_playfield(o: Node2D, from: Node):
	assert(o and from)
	var game = get_game(from)
	if game and not game.is_node_ready():
		await game.ready
	var parent: Node2D
	if game and game.new_entity_region:
		parent = game.new_entity_region
	else:
		parent = from.get_parent()
	if o.get_parent():
		o.reparent(parent)
	else:
		o.position = parent.to_local(from.global_position)
		parent.add_child(o)
	o.reset_physics_interpolation()

func on_dialogue_finished():
	_ready()

func open_dialogue(screen:CanvasItem):
	screen.visible = true
	new_entity_region.process_mode = Node.PROCESS_MODE_DISABLED
	if screen is DialogueScreen:
		screen.activate()
		await screen.dialogue_finished

	await %Curtain.close()
	screen.visible = false

	if new_entity_region:
		new_entity_region.process_mode = Node.PROCESS_MODE_INHERIT
	%Curtain.open()

func _ready():
	super()
	for d in dialgoue_screens:
		d.visible = false

	#Insert Coin
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		%TitleScreen.visible = true
		await cab.coin_inserted
		await %Curtain.close()
		%TitleScreen.visible = false
		%Curtain.open()
	else:
		%TitleScreen.visible = false

	if not lives.has_life():
		await open_dialogue(dialgoue_screens[0])
	if not current_player and lives and lives.has_life():
		await spawn_wave(waves[wave])
		spawn_player(lives.get_life())
	else:
		print("uhh. Something broke, guys")
