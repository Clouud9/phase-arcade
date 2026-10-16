@tool
extends Label
class_name InitialsLetter
## A single character slot in an [Initials] row.
##
## Owns its own character and selection animation so that [Initials] can treat
## each slot as a black box. Decorate this scene freely; the row only cares
## about [member character] and [member selected].

## The character currently shown while the slot is on.
@export var character:String = "a":
	set(value):
		character = value
		_update_visual()

## Whether this slot is the row's current selection. The selected slot pulses to
## show it is active. Exported so the animation can be previewed in the editor.
@export var selected:bool = false:
	set(value):
		selected = value
		pulse_accum = 0
		_off = false
		_update_visual()
		_update_arrows()

## What the slot shows during the off phase of its pulse. If empty, the slot is
## hidden instead, leaving a gap the size of the character.
@export var off_char:String = "_"

## How many times per second the slot pulses. Zero disables the pulse.
@export_range(0, 2, 0.1) var pulse_rate:float = 1.1
## Fraction of each pulse the slot spends on; the rest is off.
@export_range(0, 1, 0.1) var pulse_width:float = 0.6

## Show the arrows while this slot is selected, hinting it can be shifted.
@export var show_arrows:bool = true:
	set(value):
		show_arrows = value
		_update_arrows()

# --- Character ---

## Shift this slot's character through [param character_set] by [param by] steps,
## wrapping around the ends. A blank or unrecognized character enters from the
## edge matching the direction of travel.
func shift(by:int, character_set:String) -> void:
	var a := character_set.split()
	if a.is_empty():
		return
	var c_idx := a.find(character)
	if c_idx == -1:
		c_idx = 0 if by < 0 else -1
	character = a[wrapi(c_idx + by, 0, a.size())]
	# Keep the character visible while it's being edited.
	pulse_accum = 0
	_apply_off(false)

# --- Animation ---

var pulse_accum:float = 0
var _off:bool = false
var _on_layer:int = 1

func _process(delta: float) -> void:
	if not selected or pulse_rate <= 0:
		_apply_off(false)
		return
	var duration := 1.0 / pulse_rate
	pulse_accum += delta
	if pulse_accum > duration:
		pulse_accum = 0
		_apply_off(false)
	elif pulse_accum > duration * pulse_width:
		_apply_off(true)

## Enters or leaves the off phase of the pulse.
func _apply_off(off:bool) -> void:
	if _off != off:
		_off = off
		_update_visual()

## Shows [member off_char] (or hides the slot) while off, otherwise
## [member character].
func _update_visual() -> void:
	var blank := _off and off_char.is_empty()
	text = off_char if _off and not blank else character
	visibility_layer = 0 if blank else _on_layer

## Shows the arrows only while selected and [member show_arrows] is on. Uses an
## [code]Arrows[/code] child when present, otherwise any arrow siblings.
func _update_arrows() -> void:
	var show := selected and show_arrows
	var arrows := get_node_or_null("Arrows")
	if arrows:
		arrows.visible = show
		return
	for c in get_children():
		if c is CanvasItem and "Arrow" in String(c.name):
			c.visible = show

func _ready() -> void:
	_on_layer = visibility_layer
	_update_visual()
	_update_arrows()
