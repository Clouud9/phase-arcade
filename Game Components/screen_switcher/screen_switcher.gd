extends Control
class_name ScreenSwitcher
## Transitions between [Screen]s

var curtain: Curtain

# --- Operations ---

class Operation:
	var screen: Screen
	var transition: Transition # the screen's own, unless the show passed an override
	var transition_in: bool
	var others: Array[Screen] # screens displaced by this one, e.g. MOVE_ACROSS
	var time: float # seconds into the transition
	signal finished

var _pending_operations: Array[Operation]

# Resolves [param transition] against the screen's own, so a caller can override
# it for this operation only.
func _add_operation(s: Screen, transition_in: bool, other_screens: Array[Screen], transition: Transition = null) -> Operation:
	var t := transition if transition else s.transition
	var others: Array[Screen] = []
	for o in other_screens:
		if o != s:
			others.append(o)

	if t.is_instant():
		# Nothing to animate, so apply it immediately and report that there is
		# no operation to wait on.
		_settle(s, transition_in, others, t)
		return null

	var op: Operation
	for o in _pending_operations:
		if o.screen == s:
			op = o
	if not op:
		op = Operation.new()
		# A fresh operation starts from whichever resting state the screen is
		# leaving: hidden for a show, shown for a hide.
		op.time = 0.0 if transition_in else t.duration
		_pending_operations.append(op)

	# On reuse the direction may have flipped mid-flight; time is continuous, so
	# we just retarget and let it run back the other way. op.time is left alone
	# even if the new transition has a different duration, which makes progress
	# jump.
	op.screen = s
	op.transition = t
	op.transition_in = transition_in
	op.others = others

	# Raise the incoming screen now, while it is still hidden, so it slides in on
	# top instead of popping to the front once it has arrived.
	if transition_in:
		s.move_to_front()
	return op

## Advances [param op] by [param delta] seconds. Returns [code]true[/code] if the
## update concluded the operation.
func update_operation(op: Operation, delta: float) -> bool:
	var t := op.transition
	op.time += (1.0 if op.transition_in else -1.0) * delta
	var p := t.calculate_progress(op.time)

	# The owning screen always travels along its entry side: when it arrives it
	# slides in from there, and on reversal it heads straight back the way it
	# came (only the time direction changes, never the side).
	op.screen._set_state(p, -t.travel())

	# A pan carries the displaced screens along; a card drop leaves them at rest
	# until the operation concludes.
	if t.mode == Transition.Mode.MOVE_ACROSS:
		for s in op.others:
			if not _is_owned_elsewhere(s, op):
				s._set_state(1.0 - p, t.travel())

	if _reached(op, p):
		_retire(op)
		return true
	return false

# A screen with a pending operation of its own drives its own progress;
# operations that merely list it as a displaced screen must leave it alone.
func _is_owned_elsewhere(s: Screen, owner: Operation) -> bool:
	for o in _pending_operations:
		if o != owner and o.screen == s:
			return true
	return false

func _has_own_op(s: Screen) -> bool:
	for o in _pending_operations:
		if o.screen == s:
			return true
	return false

func _reached(op: Operation, progress: float) -> bool:
	return progress >= 1.0 if op.transition_in else progress <= 0.0

# Brings everything the operation touched to its resting state.
func _retire(op: Operation) -> void:
	if op.transition_in:
		_snap(op.screen, true, op.transition)
		for s in op.others:
			if not _is_owned_elsewhere(s, op):
				_snap(s, false)
	else:
		_snap(op.screen, false, op.transition)

# Applies final resting states at once: the shown screen is raised and the
# screens it displaced are hidden. Used for instant transitions and for the
# swap hidden behind the curtain. [param t] overrides [param s]'s transition.
func _settle(s: Screen, transition_in: bool, other_screens: Array[Screen], t: Transition = null) -> void:
	if transition_in:
		_snap(s, true, t)
		for o in other_screens:
			if o != s and not _has_own_op(o):
				_snap(o, false)
	else:
		_snap(s, false, t)

# Presents a screen at rest: fully shown or fully hidden.
func _snap(s: Screen, shown: bool, t: Transition = null) -> void:
	s._set_state(1.0 if shown else 0.0, (t if t else s.transition).travel())
	if shown:
		s.move_to_front()

# --- Screens ---

func get_visible_screens() -> Array[Screen]:
	var out: Array[Screen] = []
	for c in get_children():
		if c is Screen and c.visible:
			out.append(c)
	return out

## The visible [Screen] drawn above every other, or [code]null[/code] if nothing
## is visible. Showing a screen raises it with [method CanvasItem.move_to_front],
## so the topmost one is the last visible child.
func current_screen() -> Screen:
	var shown := get_visible_screens()
	if shown.is_empty():
		return null
	return shown[shown.size() - 1]

func get_screens_requiring_reversal() -> Array[Screen]:
	var out: Array[Screen] = []
	for c in get_visible_screens():
		if c.require_reversal:
			out.append(c)
	return out

func hide_screen(screen: Screen) -> void:
	if screen.transition.mode == Transition.Mode.CURTAIN:
		await _curtain_swap(screen.transition, func(): _settle(screen, false, []))
		return
	var op := _add_operation(screen, false, [])
	if op: # if the transition was instant, op will be null
		await op.finished

## Show [param screen] using its defined transition.
## If [param screen] is [code]null[/code], it will play the current screen's
## transition in reverse and show nothing.
## If [param exclusive], hides other screens
## If [param transition] is given, it replaces [member Screen.transition] for
## this show only; it is ignored when [param screen] is [code]null[/code].
## Await this method to wait for the transition(s) to finish.
func show_screen(screen: Screen, exclusive=true, transition: Transition = null) -> void:
	if screen:
		var t := transition if transition else screen.transition
		for s in get_screens_requiring_reversal():
			await hide_screen(s) # TODO: handle concurrent hiding? It's a weird usecase

		var others: Array[Screen] = []
		if exclusive:
			for s in get_visible_screens():
				if s != screen:
					others.append(s)

		if t.mode == Transition.Mode.CURTAIN:
			# Reverse anything else in flight so it settles unseen behind the
			# closed curtain.
			for o in _pending_operations:
				o.transition_in = false
			await _curtain_swap(t, func(): _settle(screen, true, others, t))
			return

		var op := _add_operation(screen, true, others, transition)
		if op:
			if exclusive:
				# An exclusive show supersedes anything else in flight: flip the
				# other pending transitions to leave, so a slower screen that is
				# still arriving doesn't end up on top of the new one.
				for o in _pending_operations:
					if o != op:
						o.transition_in = false
			await op.finished
	else:
		var dw := DextrousWaiter.new()
		for s in get_visible_screens():
			if s.transition.mode == Transition.Mode.CURTAIN:
				await _curtain_swap(s.transition, func(): _settle(s, false, []))
			else:
				var op := _add_operation(s, false, [])
				if op: # if the transition was instant, op will be null
					dw.add_signal(op.finished)
		await dw.wait_until_finished()

## Shows the given screen with no transition. Wraps [method show_screen]
func show_instant(screen: Screen, exclusive=true) -> void:
	var instant_transition = Transition.new()
	instant_transition.mode = Transition.Mode.NONE
	show_screen(screen, exclusive, instant_transition)

func cycle(num:int = 1):
	var curr = current_screen()
	var children = get_children()
	var curr_idx:int
	for i in range(children.size()):
		if children[i] == curr:
			curr_idx = i
			break
	var i = curr_idx + num
	while i >= children.size():
		i -= children.size()
	show_screen(children[i])

## Shows or hides the given screen, playing its transition
func toggle(screen: Screen) -> void:
	show_screen(null if screen.visible else screen)

# --- Curtain ---

# Closes the curtain, applies [param swap] while it hides everything, then opens
# it again. Concurrent calls serialise through the curtain's own signals.
func _curtain_swap(t: Transition, swap: Callable) -> void:
	if not curtain:
		push_warning("Cannot find curtain")
		swap.call()
		return
	await curtain.close(t)
	swap.call()
	await curtain.open(t)

# --- Main ---

func _ready() -> void:
	for c in get_children():
		if c is Curtain:
			curtain = c

	# keep sliding screens from spilling outside this control
	clip_contents = true

	# Establish the initial state: the topmost authored-visible screen is shown,
	# every other screen is hidden.
	var top:Screen
	for c in get_children():
		if c is Screen and c.visible:
			top = c
	for c in get_children():
		if c is Screen:
			_snap(c, c == top)

	if curtain and curtain.material is ShaderMaterial:
		curtain.visible = false

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


func _on_timer_timeout() -> void:
	pass # Replace with function body.
