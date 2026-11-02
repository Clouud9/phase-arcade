extends Node

signal run_started
signal level_completed(level:Dictionary)

var level_stats_template = {
	"level_1":{
		"time":0,
		"retries":1,
		"blows":0
	},
	"level_2":{
		"time":0,
		"retries":1,
		"blows":0
	},
	"level_3":{
		"time":0,
		"retries":1,
		"blows":0
	}
}
var level_stats = {
	"level_1":{
		"time":0,
		"retries":1,
		"blows":0
	},
	"level_2":{
		"time":0,
		"retries":1,
		"blows":0
	},
	"level_3":{
		"time":0,
		"retries":1,
		"blows":0
	}
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	run_started.connect(_on_run_started)
	level_completed.connect(_on_level_completed)
	
func _on_run_started():
	level_stats = level_stats_template.duplicate()
	print(level_stats)
	
func _on_level_completed(level):
	level_stats[level.name]["time"] = level.time
	level_stats[level.name]["retries"] = level.retries
	level_stats[level.name]["blows"] = level.blows
	print(level)
