@tool
class_name TextBox
extends Control

signal done_showing

var strip_tags_regex = RegEx.new()

var plain_text:String
@export var text:String:
	set(s):
		text=s
		if not is_node_ready():
			await ready

		strip_tags_regex.compile("\\[.*?\\]")
		plain_text = strip_tags_regex.sub(s, "", true)
		get_label().text = s
		get_label().visible_characters = 0


@export var sfx = &"boop"

func get_label()->RichTextLabel:
	return get_child(0).get_child(0)

func play_sfx():
	SFXPlayer.get_sfx_player(self).play_sfx(sfx)

var text_reveal_cumer = Cumer.new(40)
var sfx_cumer = Cumer.new(20, play_sfx)
func _ready() -> void:
	text=text

func _process(delta: float) -> void:
	if get_label().visible_characters < plain_text.length():
		var rate = 1.0
		match plain_text[get_label().visible_characters]: #current character
			" ":
				rate = 0.5
			",":
				rate = 0.3
			".":
				rate = 0.2
		text_reveal_cumer.add(delta * rate)
		sfx_cumer.add(delta * rate)
		get_label().visible_characters = text_reveal_cumer.i
		if get_label().visible_characters >= plain_text.length():
			done_showing.emit()


	var n = get_label()
	if n is RichTextLabel:
		custom_minimum_size.y = n.size.y
