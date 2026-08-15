class_name ActionAuthoringUtils
extends RefCounted

const EVENT_TYPES := [
	"animation",
	"window",
	"hitbox",
	"hurtbox",
	"motion",
	"feel",
	"audio",
	"vfx",
	"camera",
	"game_event",
	"note",
]

const TRACK_NAMES := {
	"animation": "Animation",
	"window": "Combat Windows",
	"hitbox": "Hitbox",
	"hurtbox": "Hurtbox",
	"motion": "Motion",
	"feel": "Feel",
	"audio": "Audio",
	"vfx": "VFX",
	"camera": "Camera",
	"game_event": "Game Events",
	"note": "Notes",
}


static func add_track(action_data: Dictionary, take_name: String, kind: String) -> Dictionary:
	if kind not in EVENT_TYPES:
		return {"ok": false, "error": "Unsupported track kind: %s" % kind}
	var updated := action_data.duplicate(true)
	var take := _find_take(updated, take_name)
	if take.is_empty():
		return {"ok": false, "error": "Take not found: %s" % take_name}
	var track := {
		"id": ActionTakeUtils.fresh_id("track"),
		"name": TRACK_NAMES.get(kind, kind.capitalize()),
		"kind": kind,
		"events": [],
	}
	var tracks: Array = take.get("tracks", [])
	tracks.append(track)
	take["tracks"] = tracks
	return {"ok": true, "data": updated, "track_id": track.id}


static func add_event(action_data: Dictionary, take_name: String, preferred_track_id: String, event_type: String, tick: int, dimension: String) -> Dictionary:
	if event_type not in EVENT_TYPES:
		return {"ok": false, "error": "Unsupported event type: %s" % event_type}
	var updated := action_data.duplicate(true)
	var take := _find_take(updated, take_name)
	if take.is_empty():
		return {"ok": false, "error": "Take not found: %s" % take_name}
	var track := _find_compatible_track(take, preferred_track_id, event_type)
	if track.is_empty():
		var track_result := add_track(updated, take_name, event_type)
		if not track_result.ok:
			return track_result
		updated = track_result.data
		take = _find_take(updated, take_name)
		track = _find_track(take, String(track_result.track_id))
	var duration := maxi(1, int(take.get("duration_ticks", 1)))
	var start_tick := clampi(tick, 0, duration)
	var event := make_event(event_type, start_tick, duration, dimension, _default_actor_id(updated))
	var events: Array = track.get("events", [])
	events.append(event)
	track["events"] = events
	return {"ok": true, "data": updated, "track_id": track.id, "event_id": event.id, "event": event}


static func remove_event(action_data: Dictionary, take_name: String, event_id: String) -> Dictionary:
	var updated := action_data.duplicate(true)
	var take := _find_take(updated, take_name)
	if take.is_empty():
		return {"ok": false, "error": "Take not found: %s" % take_name}
	for track: Variant in take.get("tracks", []):
		if not track is Dictionary:
			continue
		var events: Array = track.get("events", [])
		for index in events.size():
			if events[index] is Dictionary and String(events[index].get("id", "")) == event_id:
				events.remove_at(index)
				track["events"] = events
				return {"ok": true, "data": updated, "track_id": String(track.get("id", ""))}
	return {"ok": false, "error": "Event not found: %s" % event_id}


static func remove_track(action_data: Dictionary, take_name: String, track_id: String) -> Dictionary:
	var updated := action_data.duplicate(true)
	var take := _find_take(updated, take_name)
	if take.is_empty():
		return {"ok": false, "error": "Take not found: %s" % take_name}
	var tracks: Array = take.get("tracks", [])
	for index in tracks.size():
		if tracks[index] is Dictionary and String(tracks[index].get("id", "")) == track_id:
			var removed_events: int = tracks[index].get("events", []).size()
			tracks.remove_at(index)
			take["tracks"] = tracks
			return {"ok": true, "data": updated, "removed_events": removed_events}
	return {"ok": false, "error": "Track not found: %s" % track_id}


static func replace_event(action_data: Dictionary, take_name: String, replacement: Dictionary) -> Dictionary:
	var event_type := String(replacement.get("type", ""))
	if event_type not in EVENT_TYPES:
		return {"ok": false, "error": "Unsupported event type: %s" % event_type}
	var updated := action_data.duplicate(true)
	var take := _find_take(updated, take_name)
	if take.is_empty():
		return {"ok": false, "error": "Take not found: %s" % take_name}
	var event_id := String(replacement.get("id", ""))
	var source_track: Dictionary = {}
	var source_index := -1
	for track: Variant in take.get("tracks", []):
		if not track is Dictionary:
			continue
		var events: Array = track.get("events", [])
		for index in events.size():
			if events[index] is Dictionary and String(events[index].get("id", "")) == event_id:
				source_track = track
				source_index = index
				break
		if source_index >= 0:
			break
	if source_index < 0:
		return {"ok": false, "error": "Event not found: %s" % event_id}
	if _track_accepts_event(String(source_track.get("kind", "")), event_type):
		var source_events: Array = source_track.get("events", [])
		source_events[source_index] = replacement.duplicate(true)
		source_track["events"] = source_events
		return {"ok": true, "data": updated, "track_id": String(source_track.get("id", ""))}
	var source_events: Array = source_track.get("events", [])
	source_events.remove_at(source_index)
	source_track["events"] = source_events
	var destination := _find_compatible_track(take, "", event_type)
	if destination.is_empty():
		destination = {
			"id": ActionTakeUtils.fresh_id("track"),
			"name": TRACK_NAMES.get(event_type, event_type.capitalize()),
			"kind": event_type,
			"events": [],
		}
		var tracks: Array = take.get("tracks", [])
		tracks.append(destination)
		take["tracks"] = tracks
	var destination_events: Array = destination.get("events", [])
	destination_events.append(replacement.duplicate(true))
	destination["events"] = destination_events
	return {"ok": true, "data": updated, "track_id": String(destination.get("id", ""))}


static func make_event(event_type: String, start_tick: int, take_duration: int, dimension: String, actor_id: String = "") -> Dictionary:
	var span := 0 if event_type in ["audio", "game_event", "note"] else 5
	if event_type == "animation":
		span = 30
	return {
		"id": ActionTakeUtils.fresh_id("event"),
		"type": event_type,
		"start_tick": start_tick,
		"end_tick": mini(take_duration, start_tick + span),
		"actor_id": actor_id,
		"payload": default_payload(event_type, dimension),
	}


static func default_payload(event_type: String, dimension: String) -> Dictionary:
	var is_3d := dimension == "3d"
	match event_type:
		"animation":
			return {"clip": "", "speed": 1.0}
		"window":
			return {"kind": "active"}
		"hitbox", "hurtbox":
			return {
				"anchor": "root",
				"shape": {
					"kind": "box" if is_3d else "rect",
					"offset": [0.0, 0.0, 0.0] if is_3d else [0.0, 0.0],
					"size": [1.0, 1.0, 1.0] if is_3d else [64.0, 48.0],
				},
			}
		"motion":
			return {"delta": [0.0, 0.0, 0.0] if is_3d else [0.0, 0.0], "space": "local"}
		"feel":
			return {"kind": "hit_stop", "strength": 1.0}
		"audio", "vfx":
			return {"asset_key": "", "anchor": "root"}
		"camera":
			return {"kind": "shake", "strength": 0.5}
		"game_event":
			return {"signal": "action_event", "parameters": {}}
		"note":
			return {"text": ""}
	return {}


static func _find_take(action_data: Dictionary, take_name: String) -> Dictionary:
	for take: Variant in action_data.get("takes", []):
		if take is Dictionary and String(take.get("name", "")) == take_name:
			return take
	return {}


static func _find_track(take: Dictionary, track_id: String) -> Dictionary:
	for track: Variant in take.get("tracks", []):
		if track is Dictionary and String(track.get("id", "")) == track_id:
			return track
	return {}


static func _find_compatible_track(take: Dictionary, preferred_track_id: String, event_type: String) -> Dictionary:
	var preferred := _find_track(take, preferred_track_id)
	if not preferred.is_empty() and _track_accepts_event(String(preferred.get("kind", "")), event_type):
		return preferred
	for track: Variant in take.get("tracks", []):
		if track is Dictionary and _track_accepts_event(String(track.get("kind", "")), event_type):
			return track
	return {}


static func _track_accepts_event(track_kind: String, event_type: String) -> bool:
	if track_kind == event_type:
		return true
	return track_kind in ["audio", "vfx"] and event_type in ["audio", "vfx"]


static func _default_actor_id(action_data: Dictionary) -> String:
	var fallback := ""
	for actor: Variant in action_data.get("actors", []):
		if not actor is Dictionary:
			continue
		if fallback == "":
			fallback = String(actor.get("id", ""))
		if String(actor.get("role", "")) == "performer":
			return String(actor.get("id", ""))
	return fallback
