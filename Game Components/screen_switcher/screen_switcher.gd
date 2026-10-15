extends Control
## Transitions between [Screen]s

var curtain:Curtain

# --- Operations ---

class Operation:
	var screen:Screen
	var transition_in:bool
	var other_screens:Array[Screen] # Some transitions affect other screens e.g. MOVE_ACROSS
	signal finished

var _pending_operations:Array[Operation]

func _add_operation(s:Screen, transition_in:bool, other_screens:Array[Screen]) -> Operation:
	var op:Operation
	for o in _pending_operations:
		if o.screen == s:
			op = o
	if not op:
		op = Operation.new()
		_pending_operations.append(op)

	op.screen = s
	op.transition_in = transition_in
	return op

## Advances [param op] by [param delta] seconds. And returns [code]true[\code]
## if the update concluded the operation
func update_operation(op:Operation, delta:float) -> bool:
	return true #TODO

# --- Screens ---

func get_visible_screens() -> Array[Screen]:
	var out:Array[Screen]
	for c in get_children():
		if c is Screen and c.visible:
			out.append(c)
	return out

## Shows or hides the given screen, playing its transition
func toggle(screen: Screen) -> void:
	show_screen(null if screen.visible else screen)

## Show [param screen] using its defined transition.
## If [param screen] is [code]null[/code], it will play the current screen's
## transition in reverse and show nothing.
## If [param exclusive], hides other screens
## Await this method to wait for the transition(s) to finish.
func show_screen(screen: Screen, exclusive=true) -> void:
	if screen:
		await (_add_operation(screen, true, get_visible_screens() if exclusive else []).finished)
	else:
		var dw := DextrousWaiter.new()
		for s in get_visible_screens():
			dw.add_signal(_add_operation(s, false, []).finished)
		await dw.wait_until_finished()

# --- TODO refactor all this ---

# Runs the transition that takes `from` to `to`.
func _play(from: Screen, to: Screen) -> void:
	# The incoming screen dictates the transition; hiding it all is the reverse
	# of the outgoing screen's transition.
	var t: Transition = to.transition if to else from.transition
	if not t:
		t = Transition.new()

	current_screen = to

	# Only the screens taking part in this transition should be visible.
	_hide_others(from, to)

	match t.transition:
		Transition.Mode.CURTAIN:
			await _play_curtain(from, to, t)
		Transition.Mode.MOVE_ONTOP:
			await _play_move_on_top(from, to, t)
		Transition.Mode.MOVE_ACROSS:
			await _play_move_across(from, to, t)
		_:
			_swap(from, to)

# Instant visibility swap with no animation.
func _swap(from: Screen, to: Screen) -> void:
	if from:
		from.set_shown(false)
	if to:
		to.set_shown(true)

# Hide every screen except the transition's participants, so stray visible
# screens (e.g. ones left visible in the authored scene) don't linger on top.
func _hide_others(from: Screen, to: Screen) -> void:
	for c in get_children():
		if c is Screen and c != from and c != to:
			c.set_shown(false)
			_reset(c)

# Cover everything with the curtain, swap, then retract it.
func _play_curtain(from: Screen, to: Screen, t: Transition) -> void:
	if not curtain:
		push_warning("ScreenSwitcher: CURTAIN transition needs a %Curtain node; swapping instantly instead.")
		_swap(from, to)
		return
	await curtain.close(t.direction, t.duration)
	_swap(from, to)
	await curtain.open(t.direction, t.duration)

# The new screen slides in over the old one, like a card being placed on top.
func _play_move_on_top(from: Screen, to: Screen, t: Transition) -> void:
	if not to:
		# reverse: the outgoing screen slides back out the way it came in
		await _slide_out(from, t)
		return

	var start := -t.travel()
	to.set_shown(true)
	to.move_to_front()
	_place(to, start)
	await _tween_ratio(to, start, Vector2.ZERO, t.duration)
	_reset(to)

	if from:
		from.set_shown(false)

# The old screen pans away while the new one follows it in.
func _play_move_across(from: Screen, to: Screen, t: Transition) -> void:
	if not to:
		# reverse: the outgoing screen slides back out the way it came in
		await _slide_out(from, t)
		return

	var start := -t.travel()
	var end := t.travel()
	to.set_shown(true)
	_place(to, start)

	var tw := _new_tween()
	tw.set_parallel(true)
	tw.tween_property(to, "offset_transform_position_ratio", Vector2.ZERO, t.duration)
	if from:
		_place(from, Vector2.ZERO)
		tw.tween_property(from, "offset_transform_position_ratio", end, t.duration)
	await tw.finished

	_reset(to)
	if from:
		from.set_shown(false)
		_reset(from)

# Slides the screen off the edge it entered from, then hides it.
func _slide_out(screen: Screen, t: Transition) -> void:
	if not screen:
		return
	_place(screen, Vector2.ZERO)
	await _tween_ratio(screen, Vector2.ZERO, -t.travel(), t.duration)
	screen.set_shown(false)
	_reset(screen)

# Enables the visual offset transform and parks the screen at `ratio`.
func _place(s: Screen, ratio: Vector2) -> void:
	s.offset_transform_enabled = true
	s.offset_transform_position_ratio = ratio

# Returns the screen to an unshifted resting state.
func _reset(s: Screen) -> void:
	s.offset_transform_position_ratio = Vector2.ZERO
	s.offset_transform_enabled = false

func _tween_ratio(s: Screen, from_ratio: Vector2, to_ratio: Vector2, duration: float) -> void:
	s.offset_transform_position_ratio = from_ratio
	var tw := _new_tween()
	tw.tween_property(s, "offset_transform_position_ratio", to_ratio, duration)
	await tw.finished

# --- Main ---

func _ready() -> void:
	curtain = get_node_or_null("%Curtain")
	if not curtain:
		curtain = Curtain.new()
		add_child(curtain)
	curtain.set_openness(1.0)

	# keep sliding screens from spilling outside this control
	clip_contents = true

	# The scene may author several screens visible at once. Treat the topmost
	# (last in tree order) as the current one, then hide the rest so exactly one
	# screen is on display to start with.
	for c in get_children():
		if c is Screen and c.visible:
			current_screen = c
	for c in get_children():
		if c is Screen:
			c.set_shown(c == current_screen)
			if c != current_screen:
				_reset(c)

func _process(delta:float):
	var completed: Array[Operation] = []
	var remaining: Array[Operation] = []
	for op in _pending_operations:
		if update_operation(op, delta):
			completed.append(op)
		else:
			remaining.append(op)
	# Swap in the survivors before handling completions: a finished handler may
	# add new operations, which must not be clobbered by the swap.
	_pending_operations = remaining
	for op in completed:
		op.finished.emit()

# TODO: move this out
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Keys 1-9 map to the Screen1-Screen9 children (KEY_1..KEY_9 are
		# consecutive), so the demo works however many screens the scene has.
		var index: int = event.keycode - KEY_1
		var target := get_node_or_null("Screen%d" % (index + 1)) as Screen
		if target:
			toggle(target)
