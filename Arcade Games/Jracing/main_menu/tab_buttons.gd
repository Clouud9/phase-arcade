extends VBoxContainer
class_name MainMenuTabs

var buttons: Array[Button] = []

func tab(button: Button) -> void:
	var lambda := func() -> void:
		MenuBeep.play_for(self)
		for line: HBoxContainer in get_children():
			line.layout_direction = Control.LAYOUT_DIRECTION_LTR
		(button.get_parent() as HBoxContainer).layout_direction = Control.LAYOUT_DIRECTION_RTL
		for page: Control in get_parent().get_children():
			if page != self:
				page.visible = button.name in page.name.split("|")
	button.pressed.connect(lambda)
	buttons.append(button)

func _ready() -> void:
	tab(%VSCPU as Button)
	tab(%TA as Button)
	tab(%Online as Button)
	tab(%Settings as Button)
	tab(%Credits as Button)
	buttons.append(%Quit)
	
	%TA.connect("pressed", ta)
	%VSCPU.connect("pressed", vscpu)

func ta() -> void:
	var player := PlayerConfiguration.new()
	player.vehicle = VehicleData.new()
	player.type = PlayerConfiguration.PlayerType.LocalInput
	RaceManager.player_configuration = [player]

func vscpu() -> void:
	ta()
	var player := PlayerConfiguration.new()
	player.vehicle = VehicleData.new()
	player.type = PlayerConfiguration.PlayerType.CPU
	for i in range(7):
		RaceManager.player_configuration.append(player)
