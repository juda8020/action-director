class_name ActionActorAdapter2D
extends Node

@export var actor: Node2D
@export var animation_player: AnimationPlayer


func bind(player: ActionDirectorPlayer) -> void:
	player.event_fired.connect(_on_event_fired)
	player.motion_requested.connect(_on_motion_requested)


func _on_event_fired(_event_id: String, event_type: String, payload: Dictionary) -> void:
	if event_type == "animation" and animation_player != null:
		var clip := String(payload.get("clip", ""))
		if animation_player.has_animation(clip):
			var reverse := bool(payload.get("reverse", false))
			var speed := absf(float(payload.get("speed", 1.0))) * (-1.0 if reverse else 1.0)
			animation_player.play(clip, float(payload.get("blend", -1.0)), speed, reverse)


func _on_motion_requested(delta: Variant, space: String) -> void:
	if actor == null or not delta is Array or delta.size() < 2:
		return
	var motion := Vector2(float(delta[0]), float(delta[1]))
	actor.position += actor.transform.basis_xform(motion) if space == "local" else motion
