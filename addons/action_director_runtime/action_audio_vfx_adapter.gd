class_name ActionAudioVfxAdapter
extends Node

@export var audio_assets: Dictionary = {}
@export var vfx_scenes: Dictionary = {}
@export var spawn_parent: Node


func bind(player: ActionDirectorPlayer) -> void:
	player.event_fired.connect(_on_event_fired)


func _on_event_fired(_event_id: String, event_type: String, payload: Dictionary) -> void:
	var key := String(payload.get("asset_key", ""))
	if event_type == "audio" and audio_assets.get(key) is AudioStream:
		var audio := AudioStreamPlayer.new()
		(spawn_parent if spawn_parent != null else self).add_child(audio)
		audio.stream = audio_assets[key]
		audio.finished.connect(audio.queue_free)
		audio.play()
	elif event_type == "vfx" and vfx_scenes.get(key) is PackedScene:
		var instance: Node = vfx_scenes[key].instantiate()
		(spawn_parent if spawn_parent != null else self).add_child(instance)
