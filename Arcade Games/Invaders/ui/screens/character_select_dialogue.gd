extends DialogueScreen

@export var lives: Lives

func on_state_change():
	super()
	if lives.is_filled():
			confirm_button.disabled=false
			confirm_button.grab_focus()
	else:
			if confirm_button.has_focus():
				initial_focus.grab_focus()
			confirm_button.disabled=true

func submit(something) -> Node:
	if something is Unit and lives:
		var life_container = lives.add_life(something)
		on_state_change()
		return life_container
	return super(something)

func confirm():
	var game = Game.get_game(self)
	if game:
		if game.lives:
			lives.commune(game.lives)
			super()
