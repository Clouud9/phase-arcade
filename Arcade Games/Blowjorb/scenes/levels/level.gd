extends Node3D
class_name Level

#res://Arcade Games/Blowjorb/scenes/levels/finale.tscn
#res://Arcade Games/Blowjorb/scenes/levels/level_1.tscn
#res://Arcade Games/Blowjorb/scenes/levels/level_2.tscn
#res://Arcade Games/Blowjorb/scenes/levels/level_3.tscn
@export var level_name:String
@export var next_level:String
@onready var jorb: RigidBody3D = $Jorb
signal jorb_level_completed
const UNIVERSFIELD_MESSAGE_PING_351298 = preload("uid://dpq2pb5mevtpd")

var my_music_player
var my_sfx_player
var data_keeper

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	my_sfx_player = get_parent().my_sfx_player
	my_music_player = get_parent().my_music_player
	data_keeper = get_parent().data_keeper
	jorb.next_button.pressed.connect(_on_jorb_level_completed_menu_next)
	jorb.quit_button.pressed.connect(_on_jorb_level_completed_menu_quit)
	jorb_level_completed.connect(_on_jorb_level_completed)



func _on_success_area_3d_body_entered(body: Node3D) -> void:
	print("area jentered")
	if body == jorb:
		if not jorb.level_complete:
			print("it is the jorb")
			jorb.has_succeeded.emit()


func _on_failure_area_3d_body_entered(body: Node3D) -> void:
	if body == jorb:
		jorb.has_failed.emit()
		
func _on_jorb_level_completed_menu_next() -> void:
	my_sfx_player.play(UNIVERSFIELD_MESSAGE_PING_351298, false, false)
	var next_scene_resource = load(next_level)
	if next_scene_resource:
		var next_scene = next_scene_resource.instantiate()
		get_parent().add_child(next_scene)
		await next_scene.is_node_ready()
		queue_free()

func _on_jorb_level_completed_menu_quit() -> void:
	my_sfx_player.play(UNIVERSFIELD_MESSAGE_PING_351298, false, false)
	var start_menu_resource = load("res://Arcade Games/Blowjorb/scenes/levels/level_1.tscn")
	if start_menu_resource:
		var start_menu = start_menu_resource.instantiate()
		get_parent().add_child(start_menu)
		await start_menu.is_node_ready()
		queue_free()
	
func _on_jorb_level_completed():
	data_keeper.level_completed.emit(
		{"name":level_name,
		"time":jorb.time_passed,
		"blows":jorb.blows,
		"retries":jorb.retries}
		)
