extends Node

var stats: Stats = Stats.new()

var levels = [
	"res://level_01.tscn",
	"res://level_02.tscn"
]

var current_level = 0

func go_to_next_level() -> void:
	current_level += 1
	if current_level >= levels.size():
		current_level = 0
	get_tree().change_scene_to_file(levels[current_level])
