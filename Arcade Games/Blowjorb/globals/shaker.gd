extends Node

func shake(element:Node2D,strength:=10,duration:=0.2):
	if not element:
		return
	
	var original_pos := element.position
	var shake_steps := 10
	var tween = create_tween()
	
	for step in shake_steps:
		var shake_offset := Vector2(randf_range(-1.0,1.0),randf_range(-1.0,1.0))
		var target := original_pos+strength*shake_offset
		if step%2 == 0:
			target = original_pos
		tween.tween_property(element,"position",target,duration/float(shake_steps))
		strength*=0.75
		
	await tween.finished
	if element:
		element.position = original_pos
	
