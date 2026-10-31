extends Node
class_name OnlineMatchSetup

@export var tracks: Array[TrackData]

static var player_name: String

var connection: WebSocketPeer

func _ready() -> void:
	connection = WebSocketPeer.new()
	connection.connect_to_url("wss://j0.shinten.moe/")
	%Cancel.connect("button_down", quit)

func _process(_delta: float) -> void:
	connection.poll()
	if connection.get_ready_state() == WebSocketPeer.State.STATE_CLOSED:
		if "j0" in connection.get_requested_url():
			connection = WebSocketPeer.new()
			connection.connect_to_url("wss://pair.shinten.moe/a/JeffJero")
		else:
			queue_free()
			return
	
	if connection.get_available_packet_count() > 0:
		var packet: Dictionary = JSON.parse_string(connection.get_packet().get_string_from_utf8())
		var player_index: int = packet["index"]
		var player_count: int = packet.get("count", 2)
		
		RaceManager.player_configuration = []
		for i in range(player_count):
			var player := PlayerConfiguration.new()
			player.vehicle = VehicleData.new()
			player.type = PlayerConfiguration.PlayerType.Remote
			if i == player_index:
				player.type = PlayerConfiguration.PlayerType.LocalInput
			RaceManager.player_configuration.append(player)
		
		RaceManager.track_data = tracks[packet["seed"] as int % len(tracks)]
		RaceManager.network_update_frequency = packet.get("freq", 12)
		RaceManager.network_connection = connection
		
		connection.send_text("{\"act\":\"name\",\"index\":%s,\"name\":\"%s\"}" % [
			player_index, player_name.json_escape()])
		
		get_tree().change_scene_to_file("res://race/race.tscn")

func _exit_tree() -> void:
	if RaceManager.network_connection != connection:
		connection.close()

func quit() -> void:
	MenuBeep.play_for(self)
	queue_free()
