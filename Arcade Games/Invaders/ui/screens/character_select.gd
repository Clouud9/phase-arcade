@tool
extends Control

@export var dummy: PackedScene
@export_tool_button("populate") var f = populate

func get_life_containers(root: Node = self) -> Array[LifeContainer]:
	var out: Array[LifeContainer]
	for c in root.get_children():
		if c is LifeContainer:
			out.append(c)
		else:
			for lc in get_life_containers(c):
				out.append(lc)
	return out

func get_characters() -> Array[PackedScene]:
	var out:Array[PackedScene]
	for s in ["dizzy", "ember", "jelly", "lumi"]:
		out.append(load("res://Arcade Games/Invaders/units/players/%s.tscn" % s))
	return out

func populate():
	var life_containers = get_life_containers(self)
	var population: Array[PackedScene]
	var characters = get_characters()
	for c in characters:
		population.append(c)
	for i in range(life_containers.size() - characters.size()):
		population.append(dummy)
	population.shuffle()
	for i in range(life_containers.size()):
		life_containers[i].life_scene = population[i]
		life_containers[i].scaling = 1

func set_focus_row_pair(left: Control, right: Control):
	left.focus_neighbor_right = right.get_path()
	left.focus_next = right.get_path()
	right.focus_neighbor_left = left.get_path()
	right.focus_next = left.get_path()

func set_focus_column_pair(top: Control, bottom: Control):
	top.focus_neighbor_bottom = bottom.get_path()
	bottom.focus_neighbor_top = top.get_path()

func set_left_to_right_neighbours(a: Array[Control]):
	var prev:Control=null
	for curr in a:
		if prev:
			set_focus_row_pair(prev, curr)
		prev = curr

func set_row_neighbours(top: Array[Control], bottom: Array[Control]):
	var size_ratio = float(top.size()) / float(bottom.size())
	for i in range(top.size()):
		var j = round(i / size_ratio)
		top[i].focus_neighbor_bottom = bottom[j].get_path()
	for i in range(bottom.size()):
		var j = round(i * size_ratio)
		bottom[i].focus_neighbor_top = top[j].get_path()

func get_control_children(n: Node) -> Array[Control]:
	var out: Array[Control]
	for c in n.get_children():
		if c is Control:
			out.append(c)
	return out

func setup_nieghbours():
	var top_row = get_control_children($TopRow)
	var bottom_row = get_control_children($BottomRow)
	set_left_to_right_neighbours(top_row)
	set_left_to_right_neighbours(bottom_row)
	set_row_neighbours(top_row, bottom_row)
	var screen = DialogueScreen.get_dialogue_screen(self)
	if screen:
		screen.initial_focus = top_row[0]

func _ready():
	populate()
	setup_nieghbours()
