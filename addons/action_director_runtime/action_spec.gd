class_name ActionSpec
extends Resource

@export var schema_version: String = "1.0.0"
@export var action_id: String = ""
@export_enum("2d", "3d") var dimension: String = "2d"
@export var tick_rate: int = 60
@export var source_path: String = ""
@export var data: Dictionary = {}
@export var warnings: PackedStringArray = []


func get_take(take_name: String) -> Dictionary:
	for take: Variant in data.get("takes", []):
		if take is Dictionary and String(take.get("name", "")) == take_name:
			return take.duplicate(true)
	return {}


func get_take_names() -> PackedStringArray:
	var names := PackedStringArray()
	for take: Variant in data.get("takes", []):
		if take is Dictionary:
			names.append(String(take.get("name", "Untitled")))
	return names


func get_default_take_name() -> String:
	var names := get_take_names()
	return names[0] if not names.is_empty() else ""


func get_duration_ticks(take_name: String) -> int:
	return int(get_take(take_name).get("duration_ticks", 0))
