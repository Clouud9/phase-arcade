extends Node

func delay(t):
	return get_tree().create_timer(t).timeout
