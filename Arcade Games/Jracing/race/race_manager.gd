extends Node3D
class_name RaceManager

static var instance: RaceManager

static var track_data: TrackData
static var player_configuration: Array[PlayerConfiguration]
static var network_connection: WebSocketPeer = null
static var network_update_frequency: int

var track: Polygon2D
var players: Array[JracingPlayer]
var players_ordered: Array[JracingPlayer]
var time: int = -4 * 60
var results_time_show_min: int = 1 << 30
var results_time_show_max: int

@onready var countdown: AnimatedSprite2D = %Countdown
@onready var timer: Label = %Timer
@onready var finish: Node2D = %Finish
@onready var timer_final: PanelContainer = %TimerFinal

func _ready() -> void:
	instance = self
	track = (load(track_data.scene) as PackedScene).instantiate()
	if track.scale != Vector2.ONE:
		var poly := track.polygon
		for i in range(len(poly)):
			poly[i] *= track.scale
		track.polygon = poly
	%TrackVP.add_child(track)
	(%Music as AudioStreamPlayer).stream = load(track_data.music)
	
	var p10offset: Vector2 = track.polygon[1] - track.polygon[0]
	var start_direction: float = atan2(p10offset.y, p10offset.x)
	players = []
	for i in range(len(player_configuration)):
		var configuration := player_configuration[i]
		var player: JracingPlayer = preload("res://Arcade Games/Jracing/player/player.tscn").instantiate()
		players.append(player)
		player.index = i
		player.vehicle_data = configuration.vehicle
		player.direction = start_direction
		track.add_child(player)
		player.global_position = starting_position(i)
		var follower: Follower3D = preload("res://Arcade Games/Jracing/player/follower_3d.tscn").instantiate()
		follower.target = player
		add_child(follower)
		var controller: PlayerController
		if configuration.type == PlayerConfiguration.PlayerType.LocalInput:
			controller = PlayerController.LocalInputPlayerController.new()
			player.player_name = OnlineMatchSetup.player_name
			(%Camera as Camera).target = follower
			var ds := AudioStreamPlayer.new()
			ds.bus = "SFX"
			ds.stream = configuration.vehicle.damage_sound
			player.damage_sound = ds
			add_child(ds)
			if network_connection != null:
				network_connection.send_text("{\"act\":\"ready\",\"index\":%s}" % i)
		elif configuration.type == PlayerConfiguration.PlayerType.CPU:
			controller = PlayerController.CPUPlayerController.new()
		else:
			controller = PlayerController.RemotePlayerController.new()
			var nametag: Label = preload("res://Arcade Games/Jracing/online/nametag.tscn").instantiate()
			add_child(nametag)
			follower.tag = nametag
			player.is_ready = false
		if player.damage_sound == null:
			var ds := AudioStreamPlayer3D.new()
			ds.bus = "SFX"
			ds.stream = configuration.vehicle.damage_sound
			ds.volume_linear = 0.5
			player.damage_sound = ds
			follower.add_child(ds)
		player.controller = controller
		controller.player = player
	players_ordered = players.duplicate()
	if len(players) == 1:
		(%Rank.get_parent() as Control).visible = false
	if network_connection != null:
		time = -(1 << 30)
		for player in players:
			var line := preload("res://Arcade Games/Jracing/race/result_line.tscn").instantiate()
			if player.index == 1:
				(line.find_child("Rank") as RichTextLabel).text = (
					"2[font_size=8][table=1,t][cell]nd[/cell][/table][/font_size]")
			elif player.index == 2:
				(line.find_child("Rank") as RichTextLabel).text = (
					"3[font_size=8][table=1,t][cell]rd[/cell][/table][/font_size]")
			elif player.index > 2:
				(line.find_child("Rank") as RichTextLabel).text = (
					"%s[font_size=8][table=1,t][cell]th[/cell][/table][/font_size]" % (player.index + 1))
			%ResultsInner.add_child(line)

func _physics_process(_delta: float) -> void:
	time += 1
	if time < -99999:
		var flag: bool = true
		for player in players:
			if not player.is_ready:
				flag = false
				break
		if flag:
			time = -5 * 60
	if time < -180 or time > 40:
		countdown.visible = false
	else:
		countdown.visible = true
		countdown.frame = (time + 180) / 60
		var window_size := get_viewport().get_visible_rect().size
		countdown.scale = Vector2.ONE * window_size.y / 128
		countdown.position = window_size / 2
		if time == -180:
			(%CountdownSFX as AudioStreamPlayer).play()
		elif time == 35:
			(%Music as AudioStreamPlayer).play()
	
	if network_connection != null:
		if network_connection.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			for player in players:
				player.controller.take_json({"act": "disconnect"})
		else:
			network_connection.poll()
			while network_connection.get_available_packet_count() > 0:
				var packet := network_connection.get_packet()
				if len(packet) > 0:
					if packet[0] < len(players):
						players[packet[0]].controller.take(packet, 0)
					else:
						var data: Dictionary = JSON.parse_string(packet.get_string_from_utf8())
						players[data["index"]].controller.take_json(data)
	
	bubble_ranks()
	maybe_reveal_results()

func _process(_delta: float) -> void:
	if time > 0:
		timer.text = " %02d:%05.2f " % [
			time / 3600,
			time % 3600 / 60.0
		]
		var screen_size := get_viewport().get_visible_rect().size
		finish.position = screen_size / 2
		finish.scale = Vector2.ONE * (screen_size.y / 128)
		timer_final.position = (
			screen_size / 2 + Vector2(-timer_final.size.x / 2, finish.scale.y * 15))

func starting_position(index: int) -> Vector2:
	var line_forward := (track.polygon[1] - track.polygon[0]).normalized()
	var line_right := line_forward.rotated(PI/2)
	return track.polygon[0] - line_forward * (32 * index + 32) + line_right * (32 * (index % 4 - 1.5))

func lap_progress(position: Vector2) -> float:
	var closest_line: int
	var closest_point: Vector2
	var closest_dist_sq: float = INF
	for i in range(len(track.polygon)):
		var point := Geometry2D.get_closest_point_to_segment(
			position,
			track.polygon[i],
			track.polygon[(i+1) % len(track.polygon)]
		)
		var dist_sq := point.distance_squared_to(position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_line = i
			closest_point = point
	var segment_progress := (
		track.polygon[closest_line].distance_to(closest_point) /
		track.polygon[closest_line].distance_to(track.polygon[(closest_line+1) % len(track.polygon)])
	)
	return closest_line + segment_progress

func _exit_tree() -> void:
	instance = null

func display_rank(rank: int) -> void:
	var text: String
	if rank == 0:
		text = "[font_size=48]1[/font_size][table=1,t][cell]st[/cell][/table]"
	elif rank == 1:
		text = "[font_size=48]2[/font_size][table=1,t][cell]nd[/cell][/table]"
	elif rank == 2:
		text = "[font_size=48]3[/font_size][table=1,t][cell]rd[/cell][/table]"
	else:
		text = "[font_size=48]%s[/font_size][table=1,t][cell]th[/cell][/table]" % (rank + 1)
	(%Rank as RichTextLabel).text = text

func bubble_ranks() -> void:
	for i in range(len(players) - 1):
		if players_ordered[i + 1].ahead_of(players_ordered[i]):
			var tmp := players_ordered[i]
			players_ordered[i] = players_ordered[i + 1]
			players_ordered[i + 1] = tmp
			
			if tmp.controller is PlayerController.LocalInputPlayerController:
				display_rank(i + 1)
			elif players_ordered[i].controller is PlayerController.LocalInputPlayerController:
				display_rank(i)

static func format_time(time: float) -> String:
	if time == INF or time == 0: return "DNF"
	var ms: int = roundi(time * 1000 / 60)
	return "%02d:%02d.%03d" % [
		ms / 60000,
		ms % 60000 / 1000,
		ms % 1000
	]

func on_local_player_finish(player: JracingPlayer) -> void:
	(timer.get_parent() as Control).visible = false
	finish.visible = true
	(timer_final.get_child(0) as Label).text = format_time(player.finish_time)
	(timer_final.get_child(1) as AnimationPlayer).play("flash")
	(%Music as AudioStreamPlayer).stop()
	if AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")):
		MenuBeep.play_for(self)
	elif player == players_ordered[0]:
		(%Finish1 as AudioStreamPlayer).play()
	else:
		(%FinishX as AudioStreamPlayer).play()
	if network_connection == null:
		(%Quit as Button).visible = true
		%Quit.connect("pressed", quit)
	else:
		network_connection.send_text("{\"act\":\"goal\",\"index\":%s,\"time\":%.2f}" % [
			player.index,
			player.finish_time
		])
		results_time_show_min = time + 90
		results_time_show_max = time + 1200
		(%Rank.get_parent() as Control).visible = false

func quit() -> void:
	MenuBeep.play_for(self)
	get_tree().change_scene_to_file("res://Arcade Games/Jracing/main_menu/main_menu.tscn")

func maybe_reveal_results() -> void:
	if time < results_time_show_min: return
	if time < results_time_show_max:
		for player in players:
			if not(player.is_done() or player.controller is PlayerController.CPUPlayerController):
				return
	results_time_show_min = 1 << 30
	reveal_results()

func reveal_results() -> void:
	for i in players:
		bubble_ranks()
	for i in range(len(players)):
		var player := players_ordered[i]
		var line := %ResultsInner.get_child(i)
		(line.find_child("Name") as Label).text = player.player_name
		(line.find_child("Time") as Label).text = format_time(player.finish_time)
	(%Results as Control).visible = true
	MenuBeep.play_for(self)
	await get_tree().create_timer(0.875).timeout
	for line: Control in %ResultsInner.get_children():
		await get_tree().create_timer(0.125).timeout
		line.modulate = Color.WHITE
		MenuBeep.play_for(self)
	network_connection.close()
	network_connection = null
	await get_tree().create_timer(1).timeout
	(%ButtonsMP as Control).modulate = Color.WHITE
	MenuBeep.play_for(self)
	%QuitMP.connect("pressed", quit)
	%NextMP.connect("pressed", next_mp)

func next_mp() -> void:
	(%QuitMP as Button).disabled = true
	(%NextMP as Button).disabled = true
	MenuBeep.play_for(self)
	var connector := preload("res://Arcade Games/Jracing/online/online_match_setup.tscn").instantiate()
	connector.tree_exited.connect(maybe_quit)
	add_child(connector)

func maybe_quit() -> void:
	if network_connection == null:
		quit()
