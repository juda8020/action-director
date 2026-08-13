class_name ActionTakeUtils
extends RefCounted


static func duplicate_take(source: Dictionary, existing_names: PackedStringArray) -> Dictionary:
	var duplicate: Dictionary = source.duplicate(true)
	var base_name := "%s Copy" % String(source.get("name", "Take"))
	var candidate := base_name
	var suffix := 2
	while candidate in existing_names:
		candidate = "%s %d" % [base_name, suffix]
		suffix += 1
	duplicate.name = candidate
	duplicate.id = fresh_id("take")
	for track: Variant in duplicate.get("tracks", []):
		if not track is Dictionary:
			continue
		track.id = fresh_id("track")
		for event: Variant in track.get("events", []):
			if event is Dictionary:
				event.id = fresh_id("event")
	for branch: Variant in duplicate.get("branches", []):
		if branch is Dictionary:
			branch.id = fresh_id("branch")
	var marker_id_map := {}
	for marker: Variant in duplicate.get("markers", []):
		if marker is Dictionary:
			var old_id := String(marker.get("id", ""))
			var new_id := fresh_id("marker")
			marker.id = new_id
			marker_id_map[old_id] = new_id
	for branch: Variant in duplicate.get("branches", []):
		if branch is Dictionary and marker_id_map.has(String(branch.get("target_marker", ""))):
			branch.target_marker = marker_id_map[String(branch.target_marker)]
	return duplicate


static func first_difference_tick(first: Dictionary, second: Dictionary) -> int:
	var first_duration := int(first.get("duration_ticks", 0))
	var second_duration := int(second.get("duration_ticks", 0))
	var first_boundaries := _semantic_boundaries(first)
	var second_boundaries := _semantic_boundaries(second)
	var max_tick := maxi(first_duration, second_duration)
	for tick in range(max_tick + 1):
		if first_boundaries.get(tick, []) != second_boundaries.get(tick, []):
			return tick
	if first_duration != second_duration:
		return mini(first_duration, second_duration)
	return -1


static func fresh_id(prefix: String) -> String:
	return "%s-%s-%s" % [prefix, Time.get_ticks_usec(), randi()]


static func _semantic_boundaries(take: Dictionary) -> Dictionary:
	var result := {}
	var marker_targets := {}
	for marker: Variant in take.get("markers", []):
		if marker is Dictionary:
			var marker_semantic := [marker.get("name", ""), marker.get("tick", 0)]
			marker_targets[String(marker.get("id", ""))] = marker_semantic
			_add_signature(result, int(marker.get("tick", 0)), ["marker", marker_semantic])
	for branch: Variant in take.get("branches", []):
		if branch is Dictionary:
			var target_id := String(branch.get("target_marker", ""))
			_add_signature(result, int(branch.get("at_tick", 0)), ["branch", branch.get("condition", {}), marker_targets.get(target_id, ["missing", target_id])])
	for track: Variant in take.get("tracks", []):
		if not track is Dictionary:
			continue
		for event: Variant in track.get("events", []):
			if event is Dictionary:
				_add_signature(result, int(event.get("start_tick", 0)), ["start", track.get("kind", ""), event.get("type", ""), event.get("actor_id", ""), event.get("end_tick", 0), event.get("payload", {})])
				_add_signature(result, int(event.get("end_tick", 0)), ["end", track.get("kind", ""), event.get("type", ""), event.get("actor_id", "")])
	for tick: Variant in result.keys():
		result[tick].sort_custom(func(a: Variant, b: Variant): return JSON.stringify(a) < JSON.stringify(b))
	return result


static func _add_signature(result: Dictionary, tick: int, value: Array) -> void:
	if not result.has(tick):
		result[tick] = []
	result[tick].append(value)
