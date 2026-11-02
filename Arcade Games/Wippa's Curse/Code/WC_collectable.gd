extends Area3D

@export_enum("gold", "silver") var item_type: String = "silver"

# --- NEW: DRAG YOUR SOUND FILE HERE IN THE INSPECTOR ---
@export var pickup_sound: AudioStream

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Check if the colliding object is our player
	if body.has_method("get_knocked_down") or "CharacterBody3D" in body.name:
		
		# --- NEW: SPAWN THE AUDIO CUE SAFELY ---
		if pickup_sound:
			# Creates a temporary spatial 3D audio node exactly at the item's location
			var sound_player = AudioStreamPlayer3D.new()
			sound_player.stream = pickup_sound
			sound_player.global_position = global_position
			
			# Add it to the main world tree so it survives our queue_free()
			get_tree().root.add_child(sound_player)
			sound_player.play()
			
			# Automatically delete this temporary player only AFTER the sound finishes playing
			sound_player.finished.connect(func(): sound_player.queue_free())
		# --------------------------------------

		if item_type == "silver":
			body.has_silver_item = true
			body.reveal_collected_mesh("silver")
		elif item_type == "gold":
			body.has_gold_item = true
			body.reveal_collected_mesh("gold")
			
		queue_free()
