extends HandyLight

func _process(delta: float) -> void:
	#super()
	$AreaLight3D.light_color = light_color
	$AreaLight3D.light_energy = light_energy * 0.2
