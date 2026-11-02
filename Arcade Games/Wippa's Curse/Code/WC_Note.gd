extends CanvasLayer

@onready var note_texture: TextureRect = $NoteTexture

@export var slide_duration: float = 0.8  # Speed of the slide movement
@export var display_duration: float = 4.0 # How many seconds the note stays on screen

var original_onscreen_y: float = 0.0
var hidden_offscreen_y: float = 0.0

func _ready() -> void:
	# Small delay to let the viewport system fully initialize its resolution scales
	await get_tree().physics_frame
	
	# 1. Store the correct target Y position you set up in the editor
	original_onscreen_y = note_texture.position.y
	
	# 2. Calculate the hidden position completely underneath the bottom window frame edge
	var window_height = get_viewport().get_visible_rect().size.y
	hidden_offscreen_y = window_height + 50.0 # Adds safety margin padding
	
	# 3. Snap the note safely off-screen before the player can see it
	note_texture.position.y = hidden_offscreen_y
	
	# 4. Fire the presentation sequence automatically at the start of the game
	animate_parchment_notification()

func animate_parchment_notification() -> void:
	# Create a clean parallel interpolation engine tween
	var tween = create_tween()
	
	# --- PHASE 1: SLIDE UP ---
	# Smoothly glides the Y coordinate up from the dark offscreen limits to your view target
	tween.tween_property(note_texture, "position:y", original_onscreen_y, slide_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# --- PHASE 2: WAIT ---
	# Pauses the animation chain progress line for a few seconds so the player can read it
	tween.tween_interval(display_duration)
	
	# --- PHASE 3: SLIDE DOWN ---
	# Smoothly drives the texture back underneath the floor frame boundaries
	tween.tween_property(note_texture, "position:y", hidden_offscreen_y, slide_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
		
	# Completely remove the node infrastructure from memory resources once hidden to save cycles
	await tween.finished
	queue_free()
