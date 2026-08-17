class_name ActionSpecCodec
extends RefCounted

const CURRENT_SCHEMA := "1.0.0"
const SUPPORTED_EVENT_TYPES := {
	"animation": true,
	"motion": true,
	"hitbox": true,
	"hurtbox": true,
	"window": true,
	"feel": true,
	"audio": true,
	"vfx": true,
	"camera": true,
	"game_event": true,
	"note": true,
}
const SUPPORTED_CONDITIONS := {
	"hit": true,
	"block": true,
	"miss": true,
	"grounded": true,
	"airborne": true,
	"charge_tier": true,
	"custom_bool": true,
}


static func from_dictionary(raw: Dictionary, source_path: String = "") -> ActionSpec:
	var spec := ActionSpec.new()
	spec.schema_version = String(raw.get("schema_version", CURRENT_SCHEMA))
	spec.action_id = String(raw.get("action_id", ""))
	spec.dimension = String(raw.get("dimension", "2d"))
	spec.tick_rate = int(raw.get("tick_rate", 60))
	spec.source_path = source_path
	spec.data = raw.duplicate(true)
	spec.warnings = PackedStringArray(validate(raw).get("warnings", []))
	return spec


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Action file does not exist: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Action file could not be opened: %s" % path}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "error": "Action file is not valid JSON object data: %s" % path}
	var validation := validate(parsed)
	if not validation.ok:
		return {"ok": false, "error": "Action file failed validation.", "validation": validation, "raw": parsed}
	return {"ok": true, "spec": from_dictionary(parsed, path), "validation": validation}


static func save_json(spec: ActionSpec, path: String) -> Dictionary:
	var validation := validate(spec.data)
	if not validation.ok:
		return {"ok": false, "error": "Refusing to export an invalid action.", "validation": validation}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not write action file: %s" % path}
	file.store_string(JSON.stringify(spec.data, "\t", false, true) + "\n")
	return {"ok": true, "validation": validation}


static func validate(raw: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if String(raw.get("schema_version", "")) == "":
		errors.append("schema_version is required.")
	elif String(raw.get("schema_version", "")).get_slice(".", 0) != CURRENT_SCHEMA.get_slice(".", 0):
		warnings.append("Schema %s is newer or incompatible; unknown data will be preserved." % raw.schema_version)
	if String(raw.get("action_id", "")) == "":
		errors.append("action_id is required.")
	if String(raw.get("dimension", "")) not in ["2d", "3d"]:
		errors.append("dimension must be either 2d or 3d.")
	if int(raw.get("tick_rate", 0)) != 60:
		errors.append("tick_rate must be 60 in schema 1.x.")
	var ids := {}
	var takes: Variant = raw.get("takes", [])
	if not takes is Array or takes.is_empty():
		errors.append("At least one take is required.")
	else:
		for take_index in takes.size():
			_validate_take(takes[take_index], take_index, ids, errors, warnings)
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func _validate_take(take: Variant, take_index: int, ids: Dictionary, errors: Array[String], warnings: Array[String]) -> void:
	if not take is Dictionary:
		errors.append("Take %d must be an object." % take_index)
		return
	var take_name := String(take.get("name", ""))
	_register_id(String(take.get("id", "")), "take", ids, errors)
	if take_name == "":
		errors.append("Take %d has no name." % take_index)
	var duration := int(take.get("duration_ticks", 0))
	if duration <= 0:
		errors.append("Take %s must have a positive duration." % take_name)
	var markers := {}
	var marker_values: Variant = take.get("markers", [])
	if not marker_values is Array:
		errors.append("Take %s markers must be an array." % take_name)
	else:
		for marker: Variant in marker_values:
			if not marker is Dictionary:
				errors.append("Take %s contains an invalid marker object." % take_name)
				continue
			var marker_id := String(marker.get("id", ""))
			var marker_tick := int(marker.get("tick", -1))
			if marker_id == "" or marker_tick < 0 or marker_tick > duration:
				errors.append("Take %s contains an invalid marker." % take_name)
			else:
				_register_id(marker_id, "marker", ids, errors)
				markers[marker_id] = marker_tick
	var track_values: Variant = take.get("tracks", [])
	if not track_values is Array:
		errors.append("Take %s tracks must be an array." % take_name)
	else:
		for track: Variant in track_values:
			if not track is Dictionary:
				errors.append("Take %s contains an invalid track." % take_name)
				continue
			var track_id := String(track.get("id", ""))
			_register_id(track_id, "track", ids, errors)
			var event_values: Variant = track.get("events", [])
			if not event_values is Array:
				errors.append("Events for track %s must be an array." % track_id)
				continue
			for event: Variant in event_values:
				_validate_event(event, take_name, duration, ids, errors, warnings)
	var branch_values: Variant = take.get("branches", [])
	if not branch_values is Array:
		errors.append("Take %s branches must be an array." % take_name)
	else:
		for branch: Variant in branch_values:
			if not branch is Dictionary:
				errors.append("Take %s contains an invalid branch." % take_name)
				continue
			_register_id(String(branch.get("id", "")), "branch", ids, errors)
			var at_tick := int(branch.get("at_tick", -1))
			var target := String(branch.get("target_marker", ""))
			var condition: Dictionary = branch.get("condition", {})
			var kind := String(condition.get("kind", ""))
			if not SUPPORTED_CONDITIONS.has(kind):
				warnings.append("Branch %s uses unknown condition %s; it will not execute." % [branch.get("id", "?"), kind])
			if not markers.has(target):
				errors.append("Branch %s targets missing marker %s." % [branch.get("id", "?"), target])
			elif int(markers[target]) <= at_tick:
				errors.append("Branch %s must target a later marker." % branch.get("id", "?"))


static func _validate_event(event: Variant, take_name: String, duration: int, ids: Dictionary, errors: Array[String], warnings: Array[String]) -> void:
	if not event is Dictionary:
		errors.append("Take %s contains an invalid event." % take_name)
		return
	var event_id := String(event.get("id", ""))
	_register_id(event_id, "event", ids, errors)
	var start_tick := int(event.get("start_tick", -1))
	var end_tick := int(event.get("end_tick", start_tick))
	if start_tick < 0 or end_tick < start_tick or end_tick > duration:
		errors.append("Event %s has an invalid tick range." % event_id)
	var event_type := String(event.get("type", ""))
	if not SUPPORTED_EVENT_TYPES.has(event_type):
		warnings.append("Event %s uses unknown type %s; raw data will be preserved." % [event_id, event_type])


static func _register_id(item_id: String, kind: String, ids: Dictionary, errors: Array[String]) -> void:
	if item_id == "":
		errors.append("Action contains a %s without an id." % kind)
	elif ids.has(item_id):
		errors.append("Duplicate structural id %s (used by %s and %s)." % [item_id, ids[item_id], kind])
	else:
		ids[item_id] = kind
