extends Button

func _pressed() -> void:
    MenuBeep.play_for(self)
    OnlineMatchSetup.player_name = (%Name as LineEdit).text.strip_edges()
    if len(OnlineMatchSetup.player_name) > 0:
        var setup: OnlineMatchSetup = (
            load("res://online/online_match_setup.tscn") as PackedScene).instantiate()
        %ModalContainer.add_child(setup)
        disabled = true
        for button in (%Tabs as MainMenuTabs).buttons:
            button.disabled = true
        setup.tree_exited.connect(enable)
    else:
        (get_child(0) as AnimationPlayer).play("flash")

func enable() -> void:
    disabled = false
    for button in (%Tabs as MainMenuTabs).buttons:
        button.disabled = false
