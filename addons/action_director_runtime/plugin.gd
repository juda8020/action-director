@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"ActionDirectorPlayer",
		"Node",
		preload("res://addons/action_director_runtime/action_director_player.gd"),
		null
	)


func _exit_tree() -> void:
	remove_custom_type("ActionDirectorPlayer")
