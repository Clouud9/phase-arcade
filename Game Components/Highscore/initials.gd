@tool
extends Control
class_name Initials
## A row of selectable character slots for entering a name in initials.
##
## The slots are instantiated from [member letter] rather than authored into the
## scene, so changing [member length] or [member letter] rebuilds them. Each slot
## is an [InitialsLetter] and manages its own character and animation.

## Characters cycled through, in order, by [method shift_char].
@export var character_set:String = "abcdefghijklmnopqrstuvwxyz"

## How many character slots are shown.
@export_range(1, 16, 1) var length:int = 3:
	set(l):
		length = l
		rebuild()

## Scene instanced once per slot. Its root must be an [InitialsLetter].
@export var letter:PackedScene = preload("res://Game Components/Highscore/initials_letter.tscn"):
	set(value):
		letter = value
		rebuild()

## Index of the selected slot, moved by [method move_selection].
var selected:int = 0

# --- Slots ---

## Discards the current slots and instantiates [member length] copies of
## [member letter]. Called whenever [member length] or [member letter] changes.
func rebuild():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if not letter:
		return
	for i in range(length):
		var slot = letter.instantiate()
		if not slot is InitialsLetter:
			push_error("Initials.letter must have an InitialsLetter root, but got: %s" % slot)
			slot.free()
			return
		add_child(slot)
	selected = 0
	update_selection()

# --- Text ---

## Returns the characters currently shown in the slots.
func get_initials() -> String:
	var out:String = ""
	for c in get_children():
		if c is InitialsLetter:
			out += c.character
	return out

## Distributes [param s] across the slots, padding any spare slots with spaces.
func set_initials(s:String):
	var a = s.split()
	for i in range(get_child_count()):
		var slot := get_child(i) as InitialsLetter
		slot.character = a[i] if not s.is_empty() and i < a.size() else " "

# --- Selection ---

## Cycle the character in slot [param idx] through [member character_set],
## wrapping around the ends.
func shift_char(idx:int, by:int):
	if idx < 0 or idx >= get_child_count():
		return
	(get_child(idx) as InitialsLetter).shift(by, character_set)

## Move the selection by [param by] slots, wrapping around the ends.
func move_selection(by:int):
	var count = get_child_count()
	if count == 0:
		return
	selected = selected + by
	while selected < 0:
		selected += count
	if selected >= count:
		find_next_valid_focus().grab_focus()
	update_selection()

## Marks only the [member selected] slot as selected; all others are cleared.
func update_selection():
	for i in get_child_count():
		(get_child(i) as InitialsLetter).selected = (i == selected)

# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		shift_char(selected, 1)
	elif event.is_action_pressed("ui_down"):
		shift_char(selected, -1)
	elif event.is_action_pressed("ui_left"):
		move_selection(-1)
	elif event.is_action_pressed("ui_right"):
		move_selection(1)
	else:
		return
	var game = Game.get_game(self)
	if game:
		game.highscores_updated.emit()
	get_viewport().set_input_as_handled()

func _ready() -> void:
	rebuild()
