extends TextureRect

func bounce():
	Game.get_game(self).add_score(1)
	$AudioStreamPlayer2D.play()

var velocity:Vector2
func _process(delta: float) -> void:
	velocity += ArcadeCabinet.get_input_state(self).movement * delta
	position += velocity
	var outer = get_parent().get_global_rect()
	var inner = get_global_rect()

	if inner.position.x < outer.position.x or inner.end.x > outer.end.x:
		velocity.x *= -1
		bounce()
	if inner.position.y < outer.position.y or inner.end.y > outer.end.y:
		velocity.y *= -1
		bounce()

func die():
	velocity = Vector2.ZERO
	queue_free()
	VFX.play("pop", get_parent(), position).apply_scale(Vector2.ONE * 5)
	Game.play_sfx(self, "explosion")
	Game.get_game(self).lose()

