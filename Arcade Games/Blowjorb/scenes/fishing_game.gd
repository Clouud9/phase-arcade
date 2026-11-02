extends Node2D

@onready var jerry: AnimatedSprite2D = $Jerry
@onready var line: Line2D = $Line2D
@onready var tip: Marker2D = $FishingRod/RodSprite/Tip
@onready var end: Marker2D = $End
@onready var fishing_rod: Node2D = $FishingRod
@onready var exclamation: Node2D = $Exclamation
@onready var water: ColorRect = $water

var end_multiplier = 1
var rod_multiplier = 1
var water_multiplier = 1
var last_end_pos = 0.0
# Called when the node enters the scene tree for the first time.


	
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("blow"):
		exclamation.visible = true
		get_tree().create_timer(0.5).timeout.connect(func():exclamation.visible=false)	
	
	line.points = [	tip.global_position, end.global_position]

	if fishing_rod.rotation_degrees>-25 or fishing_rod.rotation_degrees<-45:
		rod_multiplier*=-1
	fishing_rod.rotation_degrees = fishing_rod.rotation_degrees+60*delta*rod_multiplier
	
	if end.position.x>300 or end.position.x <240:
		end_multiplier*=-1
	end.position.x = end.position.x+30*delta*end_multiplier
	
	if water.position.y>246 or water.position.y <240:
		water_multiplier*=-1
	water.position.y = water.position.y+2*delta*water_multiplier
	print(water.position.y)
func pingpong2(x, minx, maxx):
  #FIXME this assumes maxx >= minx
	var d = maxx - minx
	var dx = x - minx
	return minx + abs(wrapf(dx, -d, d))
