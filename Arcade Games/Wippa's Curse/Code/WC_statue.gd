extends Area3D

func _ready() -> void:
	# Ensure the collision signal is connected securely
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Debug print to Output window so you can see what enters the win pad zone
	print("WinZone: Touched by node named -> ", body.name)
	
	# Strict verification: If it's the player character body
	if body.has_method("get_knocked_down"):
		# Check the local player inventory flags directly inside the colliding body
		if body.has_silver_item and body.has_gold_item:
			print("WinZone SUCCESS: Player has both items! Freezing active hunting loops...")
			
			# 1. Look everywhere in the active level hierarchy for Pippa's script thread
			var pippa_node = find_node_by_method(get_tree().root, "stop_hunting_completely")
			if pippa_node:
				pippa_node.stop_hunting_completely()
				print("WinZone: Pippa successfully frozen in place!")
			else:
				print("WinZone Notice: Pippa node not found or already deleted from map.")
			
			# 2. Trigger the player's whiteout screen victory sequence directly on the entering body
			body.trigger_victory()
		else:
			print("WinZone: You stand before the statue, but you have not found both items yet!")

# Safe recursive script engine scanner that will locate Pippa anywhere in active engine memory channels
func find_node_by_method(current_node: Node, method_name: String) -> Node:
	if current_node.has_method(method_name):
		return current_node
	for child in current_node.get_children():
		var found = find_node_by_method(child, method_name)
		if found:
			return found
	return null
