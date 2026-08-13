class_name ActionCameraAdapter
extends Node

signal camera_request(payload: Dictionary)


func bind(player: ActionDirectorPlayer) -> void:
	player.event_fired.connect(_on_event_fired)


func _on_event_fired(_event_id: String, event_type: String, payload: Dictionary) -> void:
	if event_type == "camera" or (event_type == "feel" and payload.get("kind") == "camera_shake"):
		camera_request.emit(payload)
