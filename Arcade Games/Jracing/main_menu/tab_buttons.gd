extends VBoxContainer
class_name MainMenuTabs

var buttons: Array[Button] = []

func tab(button: Button) -> void:
	var lambda := func() -> void:
		MenuBeep.play_for(self)
		open_tab(button)
	button.pressed.connect(lambda)
	buttons.append(button)

func open_tab(button: Button) -> void:
	for line: HBoxContainer in get_children():
		line.layout_direction = Control.LAYOUT_DIRECTION_LTR
	(button.get_parent() as HBoxContainer).layout_direction = Control.LAYOUT_DIRECTION_RTL
	for page: Control in get_parent().get_children():
		if page != self:
			page.visible = button.name in page.name.split("|")
			# Jump to the track list so the cabinet's stick can pick a track
			if page.visible and (button == %VSCPU or button == %TA):
				(page.get_child(0) as Control).grab_focus.call_deferred()

func _ready() -> void:
	tab(%VSCPU as Button)
	tab(%TA as Button)
	tab(%Online as Button)
	tab(%Settings as Button)
	tab(%Credits as Button)
	if not %Quit.is_queued_for_deletion():
		buttons.append(%Quit)
	
	%TA.connect("pressed", ta)
	%VSCPU.connect("pressed", vscpu)
	
	# Start on the Versus CPU track list, ready for the stick and fire button
	vscpu()
	open_tab(%VSCPU as Button)

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
