class_name ActionDirectorPlayer
extends Node

signal event_fired(event_id: String, event_type: String, payload: Dictionary)
signal hitbox_opened(event_id: String, shape_data: Dictionary)
signal hitbox_closed(event_id: String)
signal motion_requested(delta: Variant, space: String)
signal cancel_window_changed(tag: String, is_open: bool)
signal branch_taken(branch_id: String, target_marker: String)
signal action_finished(action_id: String, take_name: String)
signal playback_tick_changed(tick: int)

const TICK_RATE := 60.0

var current_spec: ActionSpec
var current_take: Dictionary = {}
var current_take_name := ""
var current_tick := -1
var context: Dictionary = {}
var is_paused := false
var is_active := false
var _accumulator := 0.0
var _events_by_start: Dictionary = {}
var _events_by_end: Dictionary = {}
var _branches_by_tick: Dictionary = {}
var _markers: Dictionary = {}
var _outcomes: Dictionary = {}
var _open_hitboxes: Dictionary = {}
var _open_cancel_windows: Dictionary = {}
var _requested_cancel_tags: Dictionary = {}
var _closed_event_ids: Dictionary = {}


func _process(delta: float) -> void:
	if not is_active or is_paused:
		return
	_accumulator += delta
	var tick_seconds := 1.0 / TICK_RATE
	while _accumulator >= tick_seconds and is_active:
		_accumulator -= tick_seconds
		advance_one_tick()


func play(spec: ActionSpec, take_name: String = "", initial_context: Dictionary = {}) -> bool:
	stop()
	if spec == null:
		return false
	var chosen_take := take_name if take_name != "" else spec.get_default_take_name()
	var take := spec.get_take(chosen_take)
	if take.is_empty():
		return false
	current_spec = spec
	current_take = take
	current_take_name = chosen_take
	context = initial_context.duplicate(true)
	current_tick = -1
	_accumulator = 0.0
	is_paused = false
	is_active = true
	_index_take()
	advance_one_tick()
	return true


func stop() -> void:
	for event_id: String in _open_hitboxes.keys():
		hitbox_closed.emit(event_id)
	for event_id: String in _open_cancel_windows.keys():
		cancel_window_changed.emit(String(_open_cancel_windows[event_id]), false)
	current_spec = null
	current_take = {}
	current_take_name = ""
	current_tick = -1
	is_active = false
	is_paused = false
	_accumulator = 0.0
	_events_by_start.clear()
	_events_by_end.clear()
	_branches_by_tick.clear()
	_markers.clear()
	_outcomes.clear()
	_open_hitboxes.clear()
	_open_cancel_windows.clear()
	_requested_cancel_tags.clear()
	_closed_event_ids.clear()


func pause() -> void:
	is_paused = true


func resume() -> void:
	if is_active:
		is_paused = false


func seek_tick(target_tick: int, emit_events := false) -> void:
	if current_take.is_empty():
		return
	var clamped := clampi(target_tick, 0, int(current_take.get("duration_ticks", 0)))
	if clamped < current_tick:
		var spec := current_spec
		var take_name := current_take_name
		var saved_context := context.duplicate(true)
		play(spec, take_name, saved_context)
	if emit_events:
		while current_tick < clamped and is_active:
			advance_one_tick()
	else:
		current_tick = clamped
		playback_tick_changed.emit(current_tick)


func advance_one_tick() -> void:
	if not is_active:
		return
	current_tick += 1
	var processing_tick := current_tick
	_open_events_at_tick(processing_tick)
	_evaluate_branches_at_tick(processing_tick)
	_close_events_at_tick(processing_tick)
	playback_tick_changed.emit(current_tick)
	if current_tick >= int(current_take.get("duration_ticks", 0)):
		var finished_action := current_spec.action_id
		var finished_take := current_take_name
		_close_all_open_events()
		is_active = false
		action_finished.emit(finished_action, finished_take)


func report_outcome(event_id: String, result: String) -> void:
	if result not in ["hit", "block", "miss"]:
		push_warning("Action Director ignored unsupported outcome: %s" % result)
		return
	_outcomes[event_id] = result
	context["last_outcome"] = result
	context["last_outcome_event_id"] = event_id


func request_cancel(cancel_tag: String) -> void:
	_requested_cancel_tags[cancel_tag] = true
	context["cancel_requested:%s" % cancel_tag] = true


func _index_take() -> void:
	for marker: Variant in current_take.get("markers", []):
		if marker is Dictionary:
			_markers[String(marker.get("id", ""))] = int(marker.get("tick", 0))
	for track: Variant in current_take.get("tracks", []):
		if not track is Dictionary:
			continue
		for event: Variant in track.get("events", []):
			if not event is Dictionary:
				continue
			_index_item(_events_by_start, int(event.get("start_tick", 0)), event)
			_index_item(_events_by_end, int(event.get("end_tick", event.get("start_tick", 0))), event)
	for branch: Variant in current_take.get("branches", []):
		if branch is Dictionary:
			_index_item(_branches_by_tick, int(branch.get("at_tick", 0)), branch)


func _index_item(index: Dictionary, tick: int, item: Dictionary) -> void:
	if not index.has(tick):
		index[tick] = []
	index[tick].append(item)


func _open_events_at_tick(tick: int) -> void:
	for event: Dictionary in _events_by_start.get(tick, []):
		var event_id := String(event.get("id", ""))
		var event_type := String(event.get("type", ""))
		var payload: Dictionary = event.get("payload", {}).duplicate(true)
		if _closed_event_ids.has(event_id):
			continue
		event_fired.emit(event_id, event_type, payload)
		match event_type:
			"hitbox":
				_open_hitboxes[event_id] = true
				hitbox_opened.emit(event_id, payload.get("shape", payload))
			"motion":
				motion_requested.emit(payload.get("delta", []), String(payload.get("space", "local")))
			"window":
				if String(payload.get("kind", "")) == "cancel":
					var cancel_tag := String(payload.get("tag", "default"))
					_open_cancel_windows[event_id] = cancel_tag
					cancel_window_changed.emit(cancel_tag, true)


func _close_events_at_tick(tick: int) -> void:
	for event: Dictionary in _events_by_end.get(tick, []):
		var event_id := String(event.get("id", ""))
		var event_type := String(event.get("type", ""))
		var payload: Dictionary = event.get("payload", {})
		if event_type == "hitbox" and _open_hitboxes.has(event_id):
			_open_hitboxes.erase(event_id)
			if not _outcomes.has(event_id):
				report_outcome(event_id, "miss")
			hitbox_closed.emit(event_id)
		elif event_type == "window" and String(payload.get("kind", "")) == "cancel":
			var cancel_tag := String(_open_cancel_windows.get(event_id, payload.get("tag", "default")))
			_open_cancel_windows.erase(event_id)
			cancel_window_changed.emit(cancel_tag, false)
		_closed_event_ids[event_id] = true


func _close_all_open_events() -> void:
	for event_id: String in _open_hitboxes.keys():
		if not _outcomes.has(event_id):
			report_outcome(event_id, "miss")
		hitbox_closed.emit(event_id)
		_closed_event_ids[event_id] = true
	_open_hitboxes.clear()
	for event_id: String in _open_cancel_windows.keys():
		cancel_window_changed.emit(String(_open_cancel_windows[event_id]), false)
		_closed_event_ids[event_id] = true
	_open_cancel_windows.clear()


func _evaluate_branches_at_tick(tick: int) -> void:
	for branch: Dictionary in _branches_by_tick.get(tick, []):
		if not _condition_matches(branch.get("condition", {})):
			continue
		var target := String(branch.get("target_marker", ""))
		if not _markers.has(target) or int(_markers[target]) <= current_tick:
			continue
		_close_skipped_events(current_tick + 1, int(_markers[target]) - 1)
		current_tick = int(_markers[target]) - 1
		branch_taken.emit(String(branch.get("id", "")), target)
		break


func _close_skipped_events(from_tick: int, to_tick: int) -> void:
	if to_tick < from_tick:
		return
	for tick in range(from_tick, to_tick + 1):
		for event: Dictionary in _events_by_end.get(tick, []):
			var event_id := String(event.get("id", ""))
			if _open_hitboxes.has(event_id):
				_open_hitboxes.erase(event_id)
				if not _outcomes.has(event_id):
					report_outcome(event_id, "miss")
				hitbox_closed.emit(event_id)
			if _open_cancel_windows.has(event_id):
				cancel_window_changed.emit(String(_open_cancel_windows[event_id]), false)
				_open_cancel_windows.erase(event_id)
			_closed_event_ids[event_id] = true


func _condition_matches(condition: Dictionary) -> bool:
	var kind := String(condition.get("kind", ""))
	var expected: Variant = condition.get("value", true)
	match kind:
		"hit", "block", "miss":
			return context.has("last_outcome") and String(context.last_outcome) == kind
		"grounded":
			return bool(context.get("grounded", false)) == bool(expected)
		"airborne":
			return bool(context.get("airborne", false)) == bool(expected)
		"charge_tier":
			return int(context.get("charge_tier", 0)) == int(expected)
		"custom_bool":
			return bool(context.get(String(condition.get("key", "")), false)) == bool(expected)
	return false
