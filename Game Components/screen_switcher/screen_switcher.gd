extends Control
## Transitions between [Screen]s

var curtain:Curtain

# --- Operations ---

enum CurtainPhase {CLOSING, OPENING}

class Operation:
	var screen:Screen
	var transition_in:bool
	var other_screens:Array[Screen] # Some transitions affect other screens e.g. MOVE_ACROSS
	signal finished

	# Runtime state, unused until the operation's first update.
	var started:bool = false
	var phase:int = CurtainPhase.CLOSING # only meaningful for CURTAIN
	var time:float = 0.0 # seconds elapsed within the current curtain phase

var _pending_operations:Array[Operation]

func _add_operation(s:Screen, transition_in:bool, other_screens:Array[Screen]) -> Operation:
	# A screen is never one of its own displaced screens; callers derive the set
	# from the visible screens, which may include [param s] itself.
	var others:Array[Screen]
	for o in other_screens:
		if o != s:
			others.append(o)

	if s.transition.is_instant():
		# Nothing to animate, so apply it immediately and report that there is
		# no operation to wait on.
		_apply_instant(s, transition_in, others)
		return null

	var op:Operation
	for o in _pending_operations:
		if o.screen == s:
			op = o
	if not op:
		op = Operation.new()
		_pending_operations.append(op)

	# On reuse the direction may have flipped mid-flight; progress is continuous,
	# so we just retarget and let it run back the other way (see the plan's
	# "reverse from current progress" rule).
	op.screen = s
	op.transition_in = transition_in
	op.other_screens = others
	return op

## Advances [param op] by [param delta] seconds. And returns [code]true[/code]
## if the update concluded the operation
func update_operation(op:Operation, delta:float) -> bool:
	var t:Transition = op.screen.transition
	match t.transition:
		Transition.Mode.MOVE_ACROSS:
			return _update_across(op, t, delta)
		Transition.Mode.CURTAIN:
			return _update_curtain(op, t, delta)
		_:
			return _update_on_top(op, t, delta)

# The new screen slides in over the old one, like a card being placed on top.
# Progress 0 is fully off-screen, 1 is at rest.
func _update_on_top(op:Operation, t:Transition, delta:float) -> bool:
	if not op.started:
		op.started = true
		if op.transition_in:
			op.screen.set_shown(true)
			op.screen.move_to_front()

	var p := op.screen.update_progress(_dir(op) * delta)
	_place(op.screen, -t.travel() * (1.0 - p))

	if _reached(op, p):
		_retire(op)
		return true
	return false

# The old screen pans away while the new one follows it in. Both screens come to
# rest together as progress reaches 1.
func _update_across(op:Operation, t:Transition, delta:float) -> bool:
	if not op.started:
		op.started = true
		if op.transition_in:
			op.screen.set_shown(true)
			op.screen.move_to_front()

	var p := op.screen.update_progress(_dir(op) * delta)
	_place(op.screen, -t.travel() * (1.0 - p))
	if op.transition_in:
		for s in op.other_screens:
			if not _is_owned_elsewhere(s, op):
				_place(s, t.travel() * p)

	if _reached(op, p):
		_retire(op)
		return true
	return false

# Covers everything with the curtain, swaps, then retracts it. Drives the
# curtain's openness over two phases, each [member Transition.duration] long.
func _update_curtain(op:Operation, t:Transition, delta:float) -> bool:
	if not curtain or not (curtain.material is ShaderMaterial):
		push_warning("ScreenSwitcher: CURTAIN transition needs a Curtain with a shader; swapping instantly.")
		_retire(op)
		return true

	if not op.started:
		op.started = true
		op.phase = CurtainPhase.CLOSING
		op.time = 0.0
		curtain.visible = true
		curtain.set_openness(1.0)

	if t.duration <= 0.0:
		curtain.set_openness(1.0)
		curtain.visible = false
		_retire(op)
		return true

	op.time += delta
	var k := clampf(op.time / t.duration, 0.0, 1.0)
	match op.phase:
		CurtainPhase.CLOSING:
			curtain.set_openness(1.0 - t.blend(k))
			if k >= 1.0:
				# Fully hidden from view: swap while nothing can be seen.
				_retire(op)
				op.phase = CurtainPhase.OPENING
				op.time = 0.0
		CurtainPhase.OPENING:
			curtain.set_openness(t.blend(k))
			if k >= 1.0:
				curtain.visible = false
				return true
	return false

# A screen with a pending operation of its own drives its own progress;
# operations that merely list it as an other-screen must leave it alone.
func _is_owned_elsewhere(s:Screen, owner:Operation) -> bool:
	for o in _pending_operations:
		if o != owner and o.screen == s:
			return true
	return false

func _has_own_op(s:Screen) -> bool:
	for o in _pending_operations:
		if o.screen == s:
			return true
	return false

# +1 while entering, -1 while leaving. Progress is clamped, so once it reaches
# the target the operation is concluded.
func _dir(op:Operation) -> float:
	return 1.0 if op.transition_in else -1.0

func _reached(op:Operation, progress:float) -> bool:
	return progress >= 1.0 if op.transition_in else progress <= 0.0

# Applies the final resting state: the shown screen is reset and raised, and the
# screens it displaced are hidden.
func _retire(op:Operation) -> void:
	if op.transition_in:
		_reset(op.screen)
		_show_now(op.screen)
		for s in op.other_screens:
			if not _is_owned_elsewhere(s, op):
				_hide_now(s)
	else:
		_hide_now(op.screen)

func _apply_instant(s:Screen, transition_in:bool, other_screens:Array[Screen]) -> void:
	if transition_in:
		_show_now(s)
		for o in other_screens:
			if not _has_own_op(o):
				_hide_now(o)
	else:
		_hide_now(s)

func _show_now(s:Screen) -> void:
	s.snap(true)
	s.move_to_front()

func _hide_now(s:Screen) -> void:
	s.snap(false)
	_reset(s)

# Enables the visual offset transform and parks the screen at `ratio`.
func _place(s:Screen, ratio:Vector2) -> void:
	s.offset_transform_enabled = true
	s.offset_transform_position_ratio = ratio

# Returns the screen to an unshifted resting state.
func _reset(s:Screen) -> void:
	s.offset_transform_enabled = false

# --- Screens ---

func get_visible_screens() -> Array[Screen]:
	var out:Array[Screen]
	for c in get_children():
		if c is Screen and c.visible:
			out.append(c)
	return out

func get_screens_requiring_reversal() -> Array[Screen]:
	var out:Array[Screen]
	for c in get_visible_screens():
		if c.require_reversal:
			out.append(c)
	return out

func hide_screen(screen:Screen) -> void:
	var op := _add_operation(screen, false, [])
	if op: # if the transition was instant, op will be null
		await op.finished

## Show [param screen] using its defined transition.
## If [param screen] is [code]null[/code], it will play the current screen's
## transition in reverse and show nothing.
## If [param exclusive], hides other screens
## Await this method to wait for the transition(s) to finish.
func show_screen(screen: Screen, exclusive=true) -> void:
	if screen:
		for s in get_screens_requiring_reversal():
			await hide_screen(s) # TODO: handle concurrent hiding? It's a weird usecase
		var op := _add_operation(screen, true, get_visible_screens() if exclusive else [])
		if exclusive:
			# An exclusive show supersedes anything else in flight: flip the
			# other pending transitions to leave, so a slower screen that is
			# still arriving doesn't end up on top of the new one.
			for o in _pending_operations:
				if o != op:
					o.transition_in = false
		if op: # if the transition was instant, op will be null
			await op.finished
	else:
		var dw := DextrousWaiter.new()
		for s in get_visible_screens():
			var op := _add_operation(s, false, [])
			if op: # if the transition was instant, op will be null
				dw.add_signal(op.finished)
		await dw.wait_until_finished()

## Shows or hides the given screen, playing its transition
func toggle(screen: Screen) -> void:
	show_screen(null if screen.visible else screen)

# --- Main ---

func _ready() -> void:
	curtain = get_node_or_null("%Curtain")
	if not curtain:
		curtain = Curtain.new()
		add_child(curtain)
	if curtain.material is ShaderMaterial:
		curtain.set_openness(1.0)
	curtain.visible = false

	# keep sliding screens from spilling outside this control
	clip_contents = true

	# The scene may author several screens visible at once. Treat the topmost
	# (last in tree order) as the current one, then snap every screen to that
	# state so exactly one screen is on display to start with.
	var top:Screen
	for c in get_children():
		if c is Screen and c.visible:
			top = c
	for c in get_children():
		if c is Screen:
			c.snap(c == top)

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
