@tool
extends Label
class_name InitialsLetter
## A single character slot in an [Initials] row.
##
## Owns its own character and selection animation so that [Initials] can treat
## each slot as a black box. Decorate this scene freely; the row only cares
## about [member character] and [member selected].

## The character shown while the slot is on.
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

## Multiplies the arrows' font-relative size. 1.0 makes the arrow's texture as
## tall as the font size.
@export_range(0.0, 4.0, 0.05) var arrow_scale:float = 1.0:
	set(value):
		arrow_scale = value
		_position_arrows()

# The arrow art is a triangle occupying the bottom half of a 64px tall image.
# [constant ARROW_OFFSET] recentres it on the sprite origin so that placing the
# sprite's [member Node2D.global_position] at a point centres the visible arrow
# there, at any scale.
const ARROW_TEXTURE_HEIGHT := 64.0
const ARROW_VISUAL_HEIGHT := 32.0
const ARROW_OFFSET := Vector2(0, -16)

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

# --- Arrows ---

var _arrows:Sprite2D
var _down_arrow:Sprite2D

## Centres the arrows above and below this slot's text, scaled to the font size.
## Runs every frame because the slot's rect moves as the text and layout change.
func _position_arrows() -> void:
	if not _arrows or not is_inside_tree():
		return
	var s := get_theme_font_size("font_size") / ARROW_TEXTURE_HEIGHT * arrow_scale
	var rect := get_global_rect()
	var x := rect.get_center().x
	var half := ARROW_VISUAL_HEIGHT * s * 0.5
	_arrows.scale = Vector2(s, s)
	_arrows.offset = ARROW_OFFSET
	_arrows.global_position = Vector2(x, rect.position.y - half)
	if _down_arrow:
		_down_arrow.offset = ARROW_OFFSET
		_down_arrow.global_position = Vector2(x, rect.end.y + half)

## Shows the arrows only while selected and [member show_arrows] is on.
func _update_arrows() -> void:
	var show := selected and show_arrows
	if _arrows:
		_arrows.visible = show
	if _down_arrow:
		_down_arrow.visible = show

# --- Animation ---

var pulse_accum:float = 0
var _off:bool = false
var _on_layer:int = 1

func _process(delta: float) -> void:
	_position_arrows()
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

func _ready() -> void:
	_arrows = get_node_or_null("Arrows")
	_down_arrow = get_node_or_null("Arrows/DownArrow")
	_on_layer = visibility_layer
	_update_visual()
	_update_arrows()
	_position_arrows()
