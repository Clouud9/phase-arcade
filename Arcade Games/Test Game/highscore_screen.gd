@tool
extends Screen

func _set_shown(shown:bool):
	super(shown)
	$HighscoreContainer.populate()
