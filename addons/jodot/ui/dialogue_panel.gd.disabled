@tool
class_name DialoguePanel
extends Control

@export var width = 200
@export var width_ratio = 0.4
@export var speaker_color: Color = Color.WHITE

@onready var timeline = %Timeline

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = timeline.get_child_count() > 0
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	size.x = min(width, get_parent().size.x * width_ratio)
	position.x = get_parent().size.x - size.x

func clear():
	for c in timeline.get_children():
		c.free()
	visible = false

func set_speaker_portrait(tex:Texture2D):
	if not tex:
		return
	%SpeakerPortrait.texture = tex
	%SpeakerPortrait.position = Vector2(
		-tex.get_size().x,
		25
	)

const textbox_scn = preload("res://addons/jodot/ui/textbox.tscn")
const button_scn = preload("res://addons/jodot/ui/textbox_answer.tscn")
const descbox_scn = preload("res://addons/jodot/ui/textbox_description.tscn")
const questionbox_scn = preload("res://addons/jodot/ui/textbox_question.tscn")

func add_to_timeline(n:Control):
	timeline.add_child(n)
	%ScrollContainer.autoscroll_enabled = true

func add_box(s:String, scn:PackedScene=textbox_scn) -> TextBox:
	visible = true
	var tbox = scn.instantiate()
	add_to_timeline(tbox)
	tbox.text = s
	return tbox

func add_button(id, s:String) -> Button:
	var btn = button_scn.instantiate()
	btn.text = s
	add_to_timeline(btn)
	btn.pressed.connect(_on_answer_pressed.emit.bind(id),CONNECT_ONE_SHOT)
	return btn

func add_description_box(s:String) ->TextBox:
	return add_box(s, descbox_scn)

func add_speech_box(s:String) -> TextBox:
	s ="[color=#%s]%s[/color]" % [speaker_color.to_html(), s]
	return add_box(s)

func add_question_box(answers:Dictionary, scn:PackedScene=questionbox_scn) -> String:
	var qbox = scn.instantiate()
	add_to_timeline(qbox)
	var vbox = qbox.get_node("VBoxContainer")
	for a in answers.keys():
		add_button(a, answers[a])
		vbox.reparent(qbox)

	return await _on_answer_pressed

signal _on_answer_pressed(answer_id)
