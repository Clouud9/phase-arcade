extends Control
class_name DialogueScreen

@export var confirm_button: Button
@export var initial_focus: Control

var back_handlers: Array[Callable]
func push_back_handler(f: Callable):
	back_handlers.append(f)

func back():
	if back_handlers:
		back_handlers.pop_back().call()
		on_state_change()

func on_state_change():
	pass

func submit(something) -> Node:
	print("unhandled submit: %s" % something)
	return null

signal dialogue_finished
func confirm():
	dialogue_finished.emit()

func activate():
	visible = true
	if initial_focus:
		initial_focus.grab_focus.call_deferred()

func open():
	activate()
	await dialogue_finished

func _ready():
	activate()
	if confirm_button:
		confirm_button.disabled = true
		confirm_button.pressed.connect(confirm)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("bomb"):
		back()
		accept_event()

static func get_dialogue_screen(from: Node) -> DialogueScreen:
	while from and from is not DialogueScreen:
		from = from.get_parent()
	return from
