@tool
extends Label
class_name HighscoreLabel

@export var score:int = 0:
	set(i):
		score = i
		update()
@export var player:String = "":
	set(s):
		player = s
		update()

func update():
	if not is_node_ready():
		await ready
	for sibling in get_parent().get_children():
		if sibling is HighscoreLabel:
			sibling._apply_text()

func _apply_text():
	var place = get_index() + 1
	var widths = _column_widths()
	text = "%*d. %*d %-*s" % [widths[0], place, widths[1], score, widths[2], player]

func _column_widths() -> Array[int]:
	var place_width = 0
	var score_width = 0
	var player_width = 0
	for sibling in get_parent().get_children():
		if sibling is HighscoreLabel:
			place_width = maxi(place_width, str(sibling.get_index() + 1).length())
			score_width = maxi(score_width, str(sibling.score).length())
			player_width = maxi(player_width, sibling.player.length())
	return [place_width, score_width, player_width]

func _ready() -> void:
	child_order_changed.connect(update)
	update()
