extends SceneTree

const SpecImporter = preload("res://addons/action_director_runtime/action_spec_importer.gd")
const TakeUtils = preload("res://src/core/action_take_utils.gd")
const AuthoringUtils = preload("res://src/core/action_authoring_utils.gd")
const AppScript = preload("res://src/app/action_director_app.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_test_sample_validation()
	_test_duplicate_ids_fail()
	_test_duplicate_structural_ids_fail()
	_test_malformed_structural_collections_fail()
	_test_dimension_specific_payloads_fail()
	_test_backward_branch_fails()
	_test_unknown_events_survive()
	_test_player_event_order()
	_test_miss_fallback()
	_test_miss_branch_at_hitbox_end()
	_test_branching()
	_test_tres_cache()
	_test_frame_rate_independence()
	_test_inclusive_event_lifecycle()
	_test_project_round_trip()
	_test_project_reopens_comparison_workspace()
	_test_recovery_restores_comparison_workspace()
	_test_take_duplication()
	_test_semantic_comparison()
	_test_branch_skip_closes_cancel_window()
	_test_duplicate_semantic_equivalence()
	_test_localization_catalog()
	_test_mixamo_import_contract()
	_test_asset_name_collision_protection()
	_test_3d_clip_resolution()
	_test_real_fbx_pipeline()
	_test_bundled_fbx_demo()
	_test_bundled_2d_sprite_demo()
	_test_bundled_export_resource_paths()
	_test_tutorial_catalog()
	_test_tutorial_window_defaults()
	_test_complete_manuals()
	_test_graphical_authoring_contract()
	_test_graphical_authoring_controls()
	_test_timeline_keyboard_navigation()
	_test_explicit_compare_take_selection()
	_test_inspector_blocks_invalid_action_edits()
	_test_ui_hierarchy_states()
	_test_duplicate_take_undo_redo()
	_test_take_switch_rebinds_inspector_duration()
	if failures.is_empty():
		print("Action Director tests passed: 40/40")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Action Director tests failed: %d" % failures.size())
		quit(1)


func _test_sample_validation() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	_expect(bool(loaded.get("ok", false)), "2D sample should validate.")
	var loaded_3d := ActionSpecCodec.load_json("res://samples/actions/charge_3d.action.json")
	_expect(bool(loaded_3d.get("ok", false)), "3D sample should validate.")


func _test_duplicate_ids_fail() -> void:
	var raw := _minimal_action()
	raw.takes[0].tracks[0].events.append(raw.takes[0].tracks[0].events[0].duplicate(true))
	var result := ActionSpecCodec.validate(raw)
	_expect(not result.ok, "Duplicate event UUIDs must fail validation.")


func _test_duplicate_structural_ids_fail() -> void:
	var base := _minimal_action()
	base.takes[0]["id"] = "take-one"
	base.takes[0].tracks[0]["id"] = "shared-id"
	base.takes[0].markers = [{"id": "shared-id", "name": "Later", "tick": 8}]
	var collision := ActionSpecCodec.validate(base)
	_expect(not collision.ok, "IDs must be globally unique across structural kinds.")
	for fixture: Dictionary in [
		{"field": "take", "mutate": func(raw: Dictionary): raw.takes.append(raw.takes[0].duplicate(true))},
		{"field": "track", "mutate": func(raw: Dictionary): raw.takes[0].tracks.append(raw.takes[0].tracks[0].duplicate(true))},
		{"field": "marker", "mutate": func(raw: Dictionary): raw.takes[0].markers = [{"id": "mark", "tick": 4}, {"id": "mark", "tick": 7}]},
		{"field": "branch", "mutate": func(raw: Dictionary): raw.takes[0].branches = [{"id": "branch", "at_tick": 2, "condition": {"kind": "grounded"}, "target_marker": "later"}, {"id": "branch", "at_tick": 3, "condition": {"kind": "grounded"}, "target_marker": "later"}]; raw.takes[0].markers = [{"id": "later", "tick": 8}]},
	]:
		var raw := _minimal_action()
		raw.takes[0]["id"] = "take-one"
		fixture.mutate.call(raw)
		_expect(not ActionSpecCodec.validate(raw).ok, "Duplicate %s IDs must fail validation." % fixture.field)


func _test_malformed_structural_collections_fail() -> void:
	var raw := _minimal_action()
	raw.takes[0].markers = ["not-a-marker-object"]
	var result := ActionSpecCodec.validate(raw)
	_expect(not result.ok and "Take Default contains an invalid marker object." in result.errors, "Malformed marker entries must fail validation instead of being silently ignored.")
	for fixture: Dictionary in [
		{"label": "markers", "error": "Take Default markers must be an array.", "mutate": func(action: Dictionary): action.takes[0].markers = {"bad": true}},
		{"label": "tracks", "error": "Take Default tracks must be an array.", "mutate": func(action: Dictionary): action.takes[0].tracks = {"bad": true}},
		{"label": "events", "error": "Events for track events must be an array.", "mutate": func(action: Dictionary): action.takes[0].tracks[0].events = {"bad": true}},
		{"label": "branches", "error": "Take Default branches must be an array.", "mutate": func(action: Dictionary): action.takes[0].branches = {"bad": true}},
	]:
		var malformed := _minimal_action()
		fixture.mutate.call(malformed)
		var validation := ActionSpecCodec.validate(malformed)
		_expect(not validation.ok and String(fixture.error) in validation.errors, "Malformed %s containers must return a clear validation error." % fixture.label)
	var malformed_path := "user://malformed-collections.action.json"
	var malformed_file := FileAccess.open(malformed_path, FileAccess.WRITE)
	malformed_file.store_string(JSON.stringify(raw, "\t", false, true) + "\n")
	malformed_file.close()
	var original_text := FileAccess.get_file_as_string(malformed_path)
	var loaded := ActionSpecCodec.load_json(malformed_path)
	_expect(not loaded.ok and loaded.has("raw") and loaded.raw.takes[0].markers == raw.takes[0].markers, "A rejected action must return its original parsed data for recovery.")
	_expect(FileAccess.get_file_as_string(malformed_path) == original_text, "Validation must not rewrite a malformed source file.")
	DirAccess.remove_absolute(malformed_path)


func _test_dimension_specific_payloads_fail() -> void:
	var rejected_action: Dictionary = {}
	for fixture: Dictionary in [
		{"label": "2D motion with a 3D delta", "dimension": "2d", "error": "Event mixed-motion-2d motion delta must contain exactly 2 values for 2D.", "event": {"id": "mixed-motion-2d", "type": "motion", "start_tick": 1, "end_tick": 2, "payload": {"delta": [1, 2, 3]}}},
		{"label": "3D motion with a 2D delta", "dimension": "3d", "error": "Event mixed-motion-3d motion delta must contain exactly 3 values for 3D.", "event": {"id": "mixed-motion-3d", "type": "motion", "start_tick": 1, "end_tick": 2, "payload": {"delta": [1, 2]}}},
		{"label": "2D hitbox with a 3D shape", "dimension": "2d", "error": "Event mixed-hitbox-2d uses 3D shape kind box in a 2D action.", "event": {"id": "mixed-hitbox-2d", "type": "hitbox", "start_tick": 1, "end_tick": 2, "payload": {"shape": {"kind": "box", "offset": [0, 0, 0], "size": [1, 1, 1]}}}},
		{"label": "3D hurtbox with a 2D shape", "dimension": "3d", "error": "Event mixed-hurtbox-3d uses 2D shape kind rect in a 3D action.", "event": {"id": "mixed-hurtbox-3d", "type": "hurtbox", "start_tick": 1, "end_tick": 2, "payload": {"shape": {"kind": "rect", "offset": [0, 0], "size": [1, 1]}}}},
	]:
		var raw := _minimal_action()
		raw.dimension = fixture.dimension
		raw.takes[0].tracks[0].events = [fixture.event]
		var validation := ActionSpecCodec.validate(raw)
		_expect(not validation.ok and fixture.error in validation.errors, "%s must fail with a clear validation error instead of reaching the wrong preview or adapter." % fixture.label)
		if rejected_action.is_empty():
			rejected_action = raw
	for dimension: String in ["2d", "3d"]:
		var valid := _minimal_action()
		valid.dimension = dimension
		var vector := [0, 0, 0] if dimension == "3d" else [0, 0]
		valid.takes[0].tracks[0].events = [{"id": "valid-capsule-%s" % dimension, "type": "hurtbox", "start_tick": 1, "end_tick": 2, "payload": {"shape": {"kind": "capsule", "offset": vector, "size": vector}}}]
		_expect(ActionSpecCodec.validate(valid).ok, "A capsule with matching %s vectors must remain valid." % dimension.to_upper())
	var source_path := "user://mixed-dimension.action.json"
	var export_path := "user://mixed-dimension-export.action.json"
	DirAccess.remove_absolute(export_path)
	var source_file := FileAccess.open(source_path, FileAccess.WRITE)
	source_file.store_string(JSON.stringify(rejected_action, "\t", false, true) + "\n")
	source_file.close()
	var original_text := FileAccess.get_file_as_string(source_path)
	var loaded := ActionSpecCodec.load_json(source_path)
	_expect(not loaded.ok and loaded.has("raw") and FileAccess.get_file_as_string(source_path) == original_text, "Import must reject a mixed-dimension ActionSpec without rewriting its recovery data.")
	var exported := ActionSpecCodec.save_json(ActionSpecCodec.from_dictionary(rejected_action), export_path)
	_expect(not exported.ok and not FileAccess.file_exists(export_path), "Export must refuse a mixed-dimension ActionSpec before writing a target file.")
	DirAccess.remove_absolute(source_path)


func _test_backward_branch_fails() -> void:
	var raw := _minimal_action()
	raw.takes[0].markers = [{"id": "past", "tick": 1}]
	raw.takes[0].branches = [{"id": "bad", "at_tick": 5, "condition": {"kind": "hit"}, "target_marker": "past"}]
	var result := ActionSpecCodec.validate(raw)
	_expect(not result.ok, "Backward branches must fail validation.")


func _test_unknown_events_survive() -> void:
	var raw := _minimal_action()
	raw.takes[0].tracks[0].events[0].type = "future_event"
	raw.takes[0].tracks[0].events[0].payload.future_value = 42
	var result := ActionSpecCodec.validate(raw)
	var spec := ActionSpecCodec.from_dictionary(raw)
	_expect(result.ok and result.warnings.size() == 1, "Unknown events should warn without invalidating the file.")
	_expect(spec.data.takes[0].tracks[0].events[0].payload.future_value == 42, "Unknown event payload must be preserved.")


func _test_player_event_order() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	var player := ActionDirectorPlayer.new()
	get_root().add_child(player)
	var observed: Array[String] = []
	player.event_fired.connect(func(event_id: String, _type: String, _payload: Dictionary): observed.append(event_id))
	player.play(loaded.spec, "Take B")
	while player.is_active:
		player.advance_one_tick()
	_expect(observed == ["b-anim", "b-startup", "b-lunge", "b-whoosh", "b-active", "b-hitbox", "b-hit-stop", "b-shake", "b-spark", "b-recovery", "b-cancel"], "Runtime event order must be stable by tick and track order.")
	player.queue_free()


func _test_miss_fallback() -> void:
	var raw := _minimal_action()
	raw.takes[0].duration_ticks = 12
	raw.takes[0].markers = [{"id": "after-miss", "name": "After Miss", "tick": 10}]
	raw.takes[0].branches = [
		{"id": "premature-miss", "at_tick": 1, "condition": {"kind": "miss"}, "target_marker": "after-miss"},
		{"id": "confirmed-miss", "at_tick": 5, "condition": {"kind": "miss"}, "target_marker": "after-miss"},
	]
	raw.takes[0].tracks[0].events = [{"id": "test-hitbox", "type": "hitbox", "start_tick": 2, "end_tick": 4, "payload": {"shape": {"kind": "rect"}}}]
	var staged_player := ActionDirectorPlayer.new()
	get_root().add_child(staged_player)
	var branches: Array[String] = []
	staged_player.branch_taken.connect(func(id: String, _target: String): branches.append(id))
	staged_player.play(ActionSpecCodec.from_dictionary(raw), "Default")
	staged_player.advance_one_tick()
	_expect(branches.is_empty() and staged_player.current_tick == 1, "A miss branch must not run before a hitbox closes without an outcome.")
	while staged_player.current_tick < 5:
		staged_player.advance_one_tick()
	_expect(branches == ["confirmed-miss"], "A miss branch must run after the hitbox closes and records the fallback outcome.")
	staged_player.queue_free()
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	var player := ActionDirectorPlayer.new()
	get_root().add_child(player)
	player.play(loaded.spec, "Take A")
	for tick in 27:
		player.advance_one_tick()
	_expect(player.context.get("last_outcome") == "miss", "A hitbox with no reported outcome must close as miss.")
	player.queue_free()


func _test_miss_branch_at_hitbox_end() -> void:
	var raw := _minimal_action()
	raw.takes[0].duration_ticks = 12
	raw.takes[0].markers = [{"id": "after-miss", "name": "After Miss", "tick": 10}]
	raw.takes[0].branches = [{"id": "miss-on-close", "at_tick": 4, "condition": {"kind": "miss"}, "target_marker": "after-miss"}]
	raw.takes[0].tracks[0].events = [{"id": "test-hitbox", "type": "hitbox", "start_tick": 2, "end_tick": 4, "payload": {"shape": {"kind": "rect"}}}]
	var player := ActionDirectorPlayer.new()
	get_root().add_child(player)
	var branches: Array[String] = []
	player.branch_taken.connect(func(id: String, _target: String): branches.append(id))
	player.play(ActionSpecCodec.from_dictionary(raw), "Default")
	while player.current_tick < 4:
		player.advance_one_tick()
	_expect(branches == ["miss-on-close"] and player.current_tick == 9, "A miss branch scheduled on a hitbox end tick must see the automatic miss outcome and stage its target marker.")
	player.queue_free()


func _test_branching() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	var player := ActionDirectorPlayer.new()
	get_root().add_child(player)
	var observed := {"branch_target": ""}
	player.branch_taken.connect(func(_id: String, target: String): observed.branch_target = target)
	player.play(loaded.spec, "Take B")
	while player.current_tick < 16:
		player.advance_one_tick()
	player.report_outcome("b-hitbox", "block")
	while player.current_tick < 25:
		player.advance_one_tick()
	var branch_staged := player.current_tick == 27
	player.advance_one_tick()
	_expect(observed.branch_target == "b-recovery-marker" and branch_staged and player.current_tick == 28, "Block result should stage and execute the forward recovery marker without skipping its tick.")
	player.queue_free()


func _test_tres_cache() -> void:
	var output := "user://test-sword.action.tres"
	var result: Dictionary = SpecImporter.import_json_to_tres("res://samples/actions/sword_strike.action.json", output)
	_expect(result.ok and ResourceLoader.exists(output), "JSON action should cache as a loadable .tres resource.")
	if FileAccess.file_exists(output):
		DirAccess.remove_absolute(output)


func _test_frame_rate_independence() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	var results := {}
	for fps in [30, 60, 120]:
		var player := ActionDirectorPlayer.new()
		get_root().add_child(player)
		var observed: Array[String] = []
		player.event_fired.connect(func(event_id: String, _type: String, _payload: Dictionary): observed.append(event_id))
		player.play(loaded.spec, "Take B")
		var frames := 0
		while player.is_active and frames < fps * 3:
			player._process(1.0 / float(fps))
			frames += 1
		results[fps] = observed
		player.queue_free()
	_expect(results[30] == results[60] and results[60] == results[120], "Runtime event order must match at 30, 60, and 120 FPS.")


func _test_inclusive_event_lifecycle() -> void:
	var raw := _minimal_action()
	raw.takes[0].duration_ticks = 4
	raw.takes[0].tracks[0].events = [
		{"id": "instant-hitbox", "type": "hitbox", "start_tick": 2, "end_tick": 2, "payload": {"shape": {"kind": "rect"}}},
		{"id": "final-hitbox", "type": "hitbox", "start_tick": 4, "end_tick": 4, "payload": {"shape": {"kind": "rect"}}},
	]
	var player := ActionDirectorPlayer.new()
	get_root().add_child(player)
	var lifecycle: Array[String] = []
	player.hitbox_opened.connect(func(id: String, _shape: Dictionary): lifecycle.append("open:%s:%d" % [id, player.current_tick]))
	player.hitbox_closed.connect(func(id: String): lifecycle.append("close:%s:%d" % [id, player.current_tick]))
	player.play(ActionSpecCodec.from_dictionary(raw), "Default")
	while player.is_active:
		player.advance_one_tick()
	_expect(lifecycle == ["open:instant-hitbox:2", "close:instant-hitbox:2", "open:final-hitbox:4", "close:final-hitbox:4"], "Inclusive one-tick and final-tick hitboxes must open and close on the same tick.")
	_expect(player._open_hitboxes.is_empty(), "Action completion must not leave hitboxes open.")
	player.queue_free()


func _test_project_round_trip() -> void:
	var action := _minimal_action()
	var project := ActionProjectStore.create_from_action("/missing/original.action.json", action)
	project.workspace.timeline_height = 444
	var path := "user://round-trip.adproject"
	var saved := ActionProjectStore.save_project(project, path)
	var loaded := ActionProjectStore.load_project(path)
	_expect(saved.ok and loaded.ok, "A project with embedded ActionSpec should save and reopen.")
	var restored_action: Dictionary = loaded.project.get("action_data", {})
	_expect(restored_action.get("action_id") == action.action_id and restored_action.get("takes", []).size() == 1 and ActionSpecCodec.validate(restored_action).ok and int(loaded.project.workspace.timeline_height) == 444, "Project round-trip must preserve a valid action and workspace data without the source JSON.")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path + ".backup"):
		DirAccess.remove_absolute(path + ".backup")


func _test_project_reopens_comparison_workspace() -> void:
	var app := AppScript.new()
	app._ready()
	var third := TakeUtils.duplicate_take(app.spec.get_take("Take A"), app.spec.get_take_names())
	third.name = "Take C"
	app.spec.data.takes.append(third)
	app.spec.data.assets = []
	app.current_take_name = "Take B"
	app.compare_take_name = "Take C"
	app.compare_enabled = false
	app._rebuild_workspace()
	app._set_tick(12)
	app.project_data.workspace["future_panel_mode"] = "wide"
	var path := "user://comparison-workspace.adproject"
	app._write_project(path)
	var reopened := AppScript.new()
	reopened._ready()
	reopened._open_project(path)
	_expect(reopened.current_take_name == "Take B" and reopened.compare_take_name == "Take C", "Reopening an .adproject must restore the selected primary and comparison Takes instead of returning to the first pair.")
	_expect(not reopened.compare_enabled and reopened.current_tick == 12, "Reopening an .adproject must restore the A/B visibility and playhead tick so review can continue in place.")
	_expect(reopened.compare_button != null and not reopened.compare_button.button_pressed and not reopened.compare_stage_holder.visible, "Restored comparison state must update the visible A/B controls, not only internal fields.")
	_expect(String(reopened.project_data.workspace.get("future_panel_mode", "")) == "wide", "Saving review state must preserve unknown workspace fields for forward-compatible project recovery.")
	var legacy_path := "user://legacy-comparison-workspace.adproject"
	var legacy_project := ActionProjectStore.create_from_action("", app.spec.data)
	for key: String in ["current_take", "compare_take", "compare_enabled", "preview_tick"]:
		legacy_project.workspace.erase(key)
	ActionProjectStore.save_project(legacy_project, legacy_path)
	reopened._open_project(legacy_path)
	_expect(reopened.current_take_name == "Take A" and reopened.compare_take_name == "Take B" and reopened.compare_enabled and reopened.current_tick == 0, "Older .adproject files without review-state fields must reopen with a safe first-pair, tick-zero fallback.")
	for instance in [app, reopened]:
		instance.undo_redo.free()
		instance.undo_redo = null
		instance.free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path + ".backup"):
		DirAccess.remove_absolute(path + ".backup")
	if FileAccess.file_exists(legacy_path):
		DirAccess.remove_absolute(legacy_path)
	if FileAccess.file_exists(legacy_path + ".backup"):
		DirAccess.remove_absolute(legacy_path + ".backup")


func _test_recovery_restores_comparison_workspace() -> void:
	var recovery_path := "user://recovery.adproject"
	for suffix: String in ["", ".backup", ".tmp"]:
		if FileAccess.file_exists(recovery_path + suffix):
			DirAccess.remove_absolute(recovery_path + suffix)
	if FileAccess.file_exists("user://recovery.action.json"):
		DirAccess.remove_absolute("user://recovery.action.json")
	var app := AppScript.new()
	app._ready()
	var third := TakeUtils.duplicate_take(app.spec.get_take("Take A"), app.spec.get_take_names())
	third.name = "Take C"
	app.spec.data.takes.append(third)
	app.spec.data.assets = []
	app.current_take_name = "Take B"
	app.compare_take_name = "Take C"
	app.compare_enabled = false
	app._rebuild_workspace()
	app._set_tick(14)
	app._autosave()
	var recovered := AppScript.new()
	recovered._ready()
	recovered._recover_autosave()
	_expect(recovered.current_take_name == "Take B" and recovered.compare_take_name == "Take C", "Crash recovery must restore the primary and comparison Takes instead of reopening the first pair.")
	_expect(not recovered.compare_enabled and recovered.current_tick == 14, "Crash recovery must restore A/B visibility and the playhead tick so review can resume in place.")
	_expect(recovered.project_path == "", "A recovered workspace must require a normal Save As path instead of treating the internal recovery file as the user's project.")
	for suffix: String in ["", ".backup", ".tmp"]:
		if FileAccess.file_exists(recovery_path + suffix):
			DirAccess.remove_absolute(recovery_path + suffix)
	var legacy_file := FileAccess.open("user://recovery.action.json", FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(app.spec.data, "\t", false, true) + "\n")
	legacy_file.close()
	var legacy_recovered := AppScript.new()
	legacy_recovered._ready()
	legacy_recovered._recover_autosave()
	_expect(legacy_recovered.spec.action_id == app.spec.action_id and legacy_recovered.project_path == "", "Recovery must keep opening older action-only autosaves without binding their internal path as a normal project.")
	for instance in [app, recovered, legacy_recovered]:
		instance.undo_redo.free()
		instance.undo_redo = null
		instance.free()
	if FileAccess.file_exists("user://recovery.action.json"):
		DirAccess.remove_absolute("user://recovery.action.json")


func _test_take_duplication() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	var source: Dictionary = loaded.spec.get_take("Take B")
	var duplicate: Dictionary = TakeUtils.duplicate_take(source, loaded.spec.get_take_names())
	var source_ids := _collect_ids(source)
	var duplicate_ids := _collect_ids(duplicate)
	var overlap := source_ids.filter(func(value: String): return value in duplicate_ids)
	_expect(overlap.is_empty(), "A duplicated take must regenerate every take, track, event, branch, and marker ID.")
	_expect(duplicate.branches[0].target_marker == duplicate.markers[1].id, "Duplicated branch targets must point to duplicated markers.")


func _test_semantic_comparison() -> void:
	var first: Dictionary = _minimal_action().takes[0]
	var second: Dictionary = first.duplicate(true)
	second.markers = [{"id": "marker", "name": "Impact", "tick": 3}]
	_expect(TakeUtils.first_difference_tick(first, second) == 3, "Marker-only changes must appear in first-difference results.")
	second = first.duplicate(true)
	second.tracks[0].events[0].actor_id = "other"
	_expect(TakeUtils.first_difference_tick(first, second) == 2, "Actor assignment changes must appear in first-difference results.")
	first = _minimal_action().takes[0]
	first.tracks[0].kind = "window"
	first.tracks[0].events[0] = {"id": "startup-a", "type": "window", "start_tick": 2, "end_tick": 6, "actor_id": "hero", "payload": {"kind": "startup"}}
	second = first.duplicate(true)
	second.tracks[0].events[0].id = "startup-b"
	second.tracks[0].events[0].end_tick = 4
	_expect(TakeUtils.first_difference_tick(first, second) == 4, "Events with the same start and payload must first differ when the shorter interval ends, not when both begin.")


func _test_branch_skip_closes_cancel_window() -> void:
	var raw := _minimal_action()
	raw.takes[0].duration_ticks = 12
	raw.takes[0].markers = [{"id": "after-cancel", "name": "After Cancel", "tick": 10}]
	raw.takes[0].branches = [{"id": "skip-cancel-end", "at_tick": 4, "condition": {"kind": "custom_bool", "key": "skip", "value": true}, "target_marker": "after-cancel"}]
	raw.takes[0].tracks[0].events = [{"id": "cancel-window", "type": "window", "start_tick": 2, "end_tick": 7, "payload": {"kind": "cancel", "tag": "dodge"}}]
	var player := ActionDirectorPlayer.new()
	get_root().add_child(player)
	var states: Array[String] = []
	player.cancel_window_changed.connect(func(tag: String, opened: bool): states.append("%s:%s" % [tag, opened]))
	player.play(ActionSpecCodec.from_dictionary(raw), "Default", {"skip": true})
	while player.current_tick < 10 and player.is_active:
		player.advance_one_tick()
	_expect(states == ["dodge:true", "dodge:false"] and player._open_cancel_windows.is_empty(), "A branch that skips a cancel-window end must emit its closing signal and clear runtime state.")
	player.queue_free()


func _test_duplicate_semantic_equivalence() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	var source: Dictionary = loaded.spec.get_take("Take B")
	var duplicate: Dictionary = TakeUtils.duplicate_take(source, loaded.spec.get_take_names())
	_expect(TakeUtils.first_difference_tick(source, duplicate) == -1, "Regenerated take/track/event/marker/branch IDs must not create a semantic A/B difference.")


func _test_localization_catalog() -> void:
	var reference_keys: Array = ActionLocalization.STRINGS["en"].keys()
	for locale: String in ActionLocalization.SUPPORTED_LOCALES:
		var catalog := ActionLocalization.new(locale)
		_expect(catalog.text("open") != "open" and catalog.text("payload_invalid") != "payload_invalid", "Every supported locale must contain core editor and error strings: %s." % locale)
		_expect(catalog.text("recovered_workspace") != "recovered_workspace" and catalog.text("recovered_legacy") != "recovered_legacy" and catalog.text("tip_recover") != "tip_recover", "Every supported locale must explain current and legacy crash recovery: %s." % locale)
		var locale_keys: Array = ActionLocalization.STRINGS[locale].keys()
		for key: Variant in reference_keys:
			_expect(key in locale_keys, "Locale %s must include catalog key %s." % [locale, key])
	_expect(ActionLocalization.normalize_locale("zh-Hant-TW") == "zh_TW" and ActionLocalization.normalize_locale("fr_FR") == "en", "Locales must normalize and unsupported languages must fall back to English.")


func _test_mixamo_import_contract() -> void:
	var unsupported := ActionProjectStore.import_asset("/missing/model.obj", OS.get_user_data_dir())
	_expect(not unsupported.ok and unsupported.error_key == "asset_unsupported", "Asset errors must return a localizable key for the Mixamo FBX path.")
	var missing_project := ActionProjectStore.load_project("/definitely/missing.adproject")
	_expect(not missing_project.ok and missing_project.error_key == "project_missing" and not missing_project.error_args.is_empty(), "Project-store failures must expose localization keys and arguments.")
	var synthetic := Node3D.new()
	var skeleton := Skeleton3D.new()
	var player := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	library.add_animation("mixamo.com", Animation.new())
	player.add_animation_library("", library)
	synthetic.add_child(skeleton)
	synthetic.add_child(player)
	var metadata := ActionModelImporter.inspect_scene(synthetic)
	_expect(metadata.skeleton_count == 1 and metadata.animation_clips == ["mixamo.com"] and metadata.mixamo_compatible, "Mixamo inspection must discover skeletons and non-RESET animation clips.")
	synthetic.free()


func _test_asset_name_collision_protection() -> void:
	var fixture_root := OS.get_user_data_dir().path_join("asset-name-collision-%s" % Time.get_ticks_usec())
	var source_a := fixture_root.path_join("source-a")
	var source_b := fixture_root.path_join("source-b")
	var project_root := fixture_root.path_join("project")
	DirAccess.make_dir_recursive_absolute(source_a)
	DirAccess.make_dir_recursive_absolute(source_b)
	DirAccess.make_dir_recursive_absolute(project_root)
	var first_source := source_a.path_join("shared.png")
	var second_source := source_b.path_join("shared.png")
	var first_file := FileAccess.open(first_source, FileAccess.WRITE)
	first_file.store_string("first asset")
	first_file.close()
	var second_file := FileAccess.open(second_source, FileAccess.WRITE)
	second_file.store_string("second asset")
	second_file.close()
	var first := ActionProjectStore.import_asset(first_source, project_root)
	var second := ActionProjectStore.import_asset(second_source, project_root)
	_expect(first.ok and second.ok, "Two supported assets with the same source filename must both import successfully.")
	if first.ok and second.ok:
		_expect(first.asset.path != second.asset.path and first.asset.id != second.asset.id, "Same-name imports must receive distinct project-relative paths and asset IDs.")
		var first_copy := FileAccess.open(project_root.path_join(String(first.asset.path)), FileAccess.READ)
		var second_copy := FileAccess.open(project_root.path_join(String(second.asset.path)), FileAccess.READ)
		var first_contents := first_copy.get_as_text() if first_copy != null else ""
		var second_contents := second_copy.get_as_text() if second_copy != null else ""
		_expect(first_contents == "first asset" and second_contents == "second asset", "A later same-name import must not overwrite the previously imported asset.")
		if first_copy != null:
			first_copy.close()
		if second_copy != null:
			second_copy.close()
		for relative_path: String in [String(first.asset.path), String(second.asset.path)]:
			var copied_path := project_root.path_join(relative_path)
			if FileAccess.file_exists(copied_path):
				DirAccess.remove_absolute(copied_path)
	for source_path: String in [first_source, second_source]:
		if FileAccess.file_exists(source_path):
			DirAccess.remove_absolute(source_path)
	for directory: String in [project_root.path_join("assets"), source_a, source_b, project_root, fixture_root]:
		if DirAccess.dir_exists_absolute(directory):
			DirAccess.remove_absolute(directory)


func _test_3d_clip_resolution() -> void:
	var stage := PreviewStage3D.new()
	var ambiguous_player := AnimationPlayer.new()
	var ambiguous_library := AnimationLibrary.new()
	ambiguous_library.add_animation("HumanArmature|A_RunningJump", Animation.new())
	ambiguous_library.add_animation("HumanArmature|Man_Run", Animation.new())
	ambiguous_player.add_animation_library("", ambiguous_library)
	_expect(stage._resolve_clip(ambiguous_player, "Run") == "HumanArmature|Man_Run", "3D preview must prefer an exact imported clip suffix over an earlier fuzzy match.")
	var player := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	library.add_animation("mixamo.com", Animation.new())
	player.add_animation_library("", library)
	_expect(stage._resolve_clip(player, "charge") == "mixamo.com", "3D preview must fall back to the first imported Mixamo clip when the authored alias is not present.")
	_expect(stage._resolve_clip(player, "mixamo") == "mixamo.com", "3D preview must resolve a partial Mixamo clip name.")
	ambiguous_player.free()
	player.free()
	stage.free()


func _test_real_fbx_pipeline() -> void:
	var source := ProjectSettings.globalize_path("res://tests/fixtures/cc0-animated-man.fbx")
	var destination_root := OS.get_user_data_dir().path_join("fbx-fixture-project")
	DirAccess.make_dir_recursive_absolute(destination_root)
	var imported := ActionProjectStore.import_asset(source, destination_root)
	_expect(imported.ok, "A real CC0 animated FBX fixture must parse through Godot's UFBX pipeline.")
	if imported.ok:
		var clips: Array = imported.asset.get("animation_clips", [])
		_expect(int(imported.asset.get("skeleton_count", 0)) > 0 and int(imported.asset.get("mesh_count", 0)) > 0 and not clips.is_empty(), "Real FBX import must discover a skeleton, visible mesh, and animation clip.")
		var loaded := ActionModelImporter.load_scene(destination_root.path_join(String(imported.asset.path)))
		_expect(loaded.ok, "The copied project-relative FBX must load into a generated Node3D scene.")
		if loaded.ok:
			var stage := PreviewStage3D.new()
			var players: Array[AnimationPlayer] = []
			var stack: Array[Node] = [loaded.scene]
			while not stack.is_empty():
				var node: Node = stack.pop_back()
				if node is AnimationPlayer:
					players.append(node)
				for child in node.get_children():
					stack.append(child)
			_expect(not players.is_empty() and stage._resolve_clip(players[0], String(clips[0])) != "", "A preview stage must resolve and play the animation clip generated from the real FBX.")
			loaded.scene.free()
			stage.free()
	var copied := destination_root.path_join("assets/cc0-animated-man.fbx")
	if FileAccess.file_exists(copied):
		DirAccess.remove_absolute(copied)
	var asset_directory := destination_root.path_join("assets")
	if DirAccess.dir_exists_absolute(asset_directory):
		DirAccess.remove_absolute(asset_directory)
	if DirAccess.dir_exists_absolute(destination_root):
		DirAccess.remove_absolute(destination_root)


func _test_bundled_fbx_demo() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/charge_3d.action.json")
	_expect(loaded.ok and loaded.spec.data.get("assets", []).size() == 1, "The 3D sample must ship with one redistributable FBX demo asset.")
	if not loaded.ok or loaded.spec.data.get("assets", []).is_empty():
		return
	var asset: Dictionary = loaded.spec.data.assets[0]
	var asset_path := ProjectSettings.globalize_path("res://samples/actions").path_join(String(asset.get("path", ""))).simplify_path()
	var inspected := ActionModelImporter.inspect_file(asset_path)
	_expect(FileAccess.file_exists(asset_path) and inspected.ok, "The bundled CC0 FBX must exist and load through the production UFBX path.")
	if inspected.ok:
		_expect(inspected.metadata.mixamo_compatible and "HumanArmature|Man_Run" in inspected.metadata.animation_clips, "The bundled demo must expose a humanoid skeleton, mesh, and the animation clip used by the 3D action.")
	_expect(String(asset.get("license", "")) == "CC0-1.0" and FileAccess.file_exists("res://samples/assets/LICENSE-cc0-animated-man.txt"), "The redistributable FBX demo must carry an explicit CC0 license record and must not be presented as a Mixamo asset.")


func _test_bundled_2d_sprite_demo() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	_expect(loaded.ok and loaded.spec.data.get("assets", []).size() == 1, "The 2D sample must ship with one playable spritesheet asset.")
	if not loaded.ok or loaded.spec.data.get("assets", []).is_empty():
		return
	var asset: Dictionary = loaded.spec.data.assets[0]
	var asset_path := ProjectSettings.globalize_path("res://samples/actions").path_join(String(asset.get("path", ""))).simplify_path()
	var image := Image.new()
	var image_error := image.load(asset_path)
	_expect(image_error == OK and image.get_width() % 8 == 0 and image.detect_alpha() != Image.ALPHA_NONE, "The bundled 2D sheet must be a transparent eight-column image that can be sliced without drift.")
	_expect(int(asset.get("frame_count", 0)) == 8 and int(asset.get("layout", {}).get("columns", 0)) == 8, "The 2D sample must declare all eight animation frames in ActionSpec asset metadata.")
	var stage := PreviewStage2D.new()
	stage.set_take(loaded.spec, "Take B")
	stage.imported_asset = asset
	stage.set_tick(0)
	var first_frame := stage._sprite_frame_index()
	stage.set_tick(18)
	var contact_frame := stage._sprite_frame_index()
	_expect(first_frame == 0 and contact_frame > first_frame, "2D rehearsal ticks must advance the bundled sprite instead of stretching the whole sheet as one image.")
	stage.free()
	_expect(String(asset.get("license", "")) == "CC0-1.0" and FileAccess.file_exists("res://samples/assets/LICENSE-original-sword-fighter.txt"), "The original 2D demo must carry an explicit redistributable license record.")


func _test_bundled_export_resource_paths() -> void:
	var app := AppScript.new()
	app.action_path = "res://samples/actions/sword_strike.action.json"
	_expect(app._project_asset_root() == "res://samples/actions", "Bundled sample assets must retain res:// paths so exported PCK resources remain loadable.")
	app.undo_redo.free()
	app.undo_redo = null
	app.free()
	var texture := ResourceLoader.load("res://samples/assets/sword-fighter-slash-sheet.png")
	_expect(texture is Texture2D, "The bundled 2D sample must load through Godot's export-safe resource path.")
	var model := ActionModelImporter.load_scene("res://samples/assets/cc0-animated-man.fbx")
	_expect(model.ok and model.scene is Node3D, "The bundled FBX must instantiate through its imported PackedScene, matching exported PCK behavior.")
	if model.ok:
		model.scene.free()


func _test_tutorial_catalog() -> void:
	_expect(ActionTutorialCatalog.CHAPTER_IDS.size() == 10, "Tutorial center must expose all ten purpose, workflow, and application chapters.")
	for locale: String in ActionLocalization.SUPPORTED_LOCALES:
		var chapters := ActionTutorialCatalog.get_chapters(locale)
		_expect(chapters.size() == ActionTutorialCatalog.CHAPTER_IDS.size(), "Every locale must include every tutorial chapter: %s." % locale)
		for chapter: Dictionary in chapters:
			_expect(String(chapter.get("title", "")) != "" and String(chapter.get("summary", "")) != "" and chapter.get("steps", []).size() >= 3, "Tutorial chapters need a title, summary, and actionable steps in %s." % locale)
			_expect(String(chapter.get("action", "none")) in ["none", "open_2d", "open_3d"], "Tutorial chapter actions must connect only to supported editor workflows in %s." % locale)
			for step: Variant in chapter.get("steps", []):
				_expect(step is Array and step.size() == 2 and String(step[0]) != "" and String(step[1]) != "", "Every tutorial step needs a heading and instruction in %s." % locale)


func _test_tutorial_window_defaults() -> void:
	var center := ActionTutorialCenter.new()
	center.visible = true
	center.configure(ActionLocalization.new("zh_TW"), ["quick_start"], false)
	center._ready()
	_expect(not center.visible, "Tutorial Window must remain hidden until first-run or the Tutorial button explicitly opens it.")
	_expect(center.chapter_list.item_count == ActionTutorialCatalog.CHAPTER_IDS.size(), "Tutorial Window must render every workflow chapter.")
	_expect(center.content_scroll.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "Tutorial content must expand across the available right column.")
	_expect(center.content_scroll.get_child(0).custom_minimum_size.x >= 420.0, "Tutorial content must keep a readable text-column width at the supported minimum window size.")
	_expect(center.content_scroll.focus_mode == Control.FOCUS_ALL, "Tutorial content must provide a keyboard-focusable scrolling region.")
	_expect(center.progress_label.text.contains("1") and center.progress_label.text.contains("10"), "Tutorial Window must render persisted completion progress.")
	center.free()


func _test_complete_manuals() -> void:
	var paths := {
		"en": "res://docs/USER_GUIDE.en.md",
		"zh_TW": "res://docs/USER_GUIDE.zh_TW.md",
		"ja": "res://docs/USER_GUIDE.ja.md",
		"ko": "res://docs/USER_GUIDE.ko.md",
	}
	for locale: String in ActionLocalization.SUPPORTED_LOCALES:
		var path: String = paths[locale]
		_expect(FileAccess.file_exists(path), "A complete offline manual must ship for %s." % locale)
		if not FileAccess.file_exists(path):
			continue
		var source := FileAccess.get_file_as_string(path)
		_expect(source.length() >= 6000, "The complete manual must contain substantial workflow detail in %s." % locale)
		_expect(source.count("## ") >= 16, "The complete manual must cover purpose, workflow, application, integration, and troubleshooting in %s." % locale)
		for contract_term: String in ["ActionSpec", ".adproject", ".action.json", "Mixamo", "Godot 4.7", "report_outcome"]:
			_expect(source.contains(contract_term), "The %s manual must explain %s." % [locale, contract_term])
	var manual := ActionManualWindow.new()
	manual.configure(ActionLocalization.new("zh_TW"))
	manual._ready()
	_expect(not manual.visible, "Complete manual Window must remain hidden until explicitly opened.")
	_expect(manual.manual_text.text.length() >= 6000, "Complete manual Window must load the current locale's full guide.")
	_expect(manual.manual_text.selection_enabled, "Complete manual text must be selectable for copying examples.")
	manual.free()


func _test_graphical_authoring_contract() -> void:
	var raw := _minimal_action()
	raw.actors = [{"id": "hero", "name": "Hero", "role": "performer"}]
	var track_result := AuthoringUtils.add_track(raw, "Default", "hitbox")
	_expect(track_result.ok, "Graphical authoring must add a supported empty track.")
	var event_result := AuthoringUtils.add_event(track_result.data, "Default", track_result.track_id, "hitbox", 4, "2d")
	_expect(event_result.ok, "Graphical authoring must add an event at the playhead.")
	if event_result.ok:
		var event: Dictionary = event_result.event
		_expect(event.actor_id == "hero" and event.start_tick == 4 and event.end_tick == 9, "New events must select the performer and stay inside the take duration.")
		_expect(event.payload.shape.kind == "rect" and event.payload.shape.offset.size() == 2, "2D hitboxes must receive an editable 2D shape payload.")
		_expect(ActionSpecCodec.validate(event_result.data).ok, "Graphically authored tracks and events must remain valid ActionSpec data.")
		var removed_event := AuthoringUtils.remove_event(event_result.data, "Default", event_result.event_id)
		var removed_track := AuthoringUtils.remove_track(removed_event.data, "Default", event_result.track_id)
		_expect(removed_event.ok and removed_track.ok and removed_track.removed_events == 0, "Graphical authoring must delete selected events and tracks without corrupting the take.")
	var event_3d := AuthoringUtils.make_event("hitbox", 8, 10, "3d", "fighter")
	_expect(event_3d.end_tick == 10 and event_3d.payload.shape.kind == "box" and event_3d.payload.shape.offset.size() == 3, "3D events must clamp to duration and receive 3D shape data.")


func _test_graphical_authoring_controls() -> void:
	var app := AppScript.new()
	app.localization = ActionLocalization.new("en")
	var center := app._build_center()
	app.add_child(center)
	_expect(app.event_type_picker.item_count == AuthoringUtils.EVENT_TYPES.size(), "Timeline authoring toolbar must expose every supported event type.")
	_expect(app.timeline != null and app.timeline.focus_mode == Control.FOCUS_ALL, "Timeline authoring must remain keyboard focusable.")
	app.undo_redo.free()
	app.undo_redo = null
	app.free()
	var inspector_panel := ActionInspectorPanel.new()
	inspector_panel.localization = ActionLocalization.new("en")
	inspector_panel._ready()
	var raw := _minimal_action()
	raw.actors = [{"id": "hero", "name": "Hero", "role": "performer"}]
	inspector_panel.set_spec(ActionSpecCodec.from_dictionary(raw), "Default")
	inspector_panel.inspect_event(raw.takes[0].tracks[0].events[0])
	_expect(String(inspector_panel.type_picker.get_selected_metadata()) == "game_event", "Inspector must select and edit the event type.")
	_expect(inspector_panel.actor_picker.item_count == 2, "Inspector must offer no-actor and every ActionSpec actor option.")
	_expect(int(inspector_panel.start_spin.max_value) == 10 and int(inspector_panel.end_spin.max_value) == 10, "Inspector timing controls must be bounded by the active take duration.")
	var observed := {"event": {}}
	inspector_panel.event_changed.connect(func(event: Dictionary): observed.event = event)
	inspector_panel.start_spin.value = 999
	inspector_panel.end_spin.value = 999
	inspector_panel._apply_changes()
	_expect(int(observed.event.get("start_tick", -1)) == 10 and int(observed.event.get("end_tick", -1)) == 10, "Inspector must prevent event timing from exceeding the take duration.")
	inspector_panel.free()


func _test_timeline_keyboard_navigation() -> void:
	var loaded := ActionSpecCodec.load_json("res://samples/actions/sword_strike.action.json")
	var timeline := ActionTimelineView.new()
	timeline.set_take(loaded.spec, "Take A")
	get_root().add_child(timeline)
	timeline._ready()
	_expect(timeline.focus_mode == Control.FOCUS_ALL, "Timeline keyboard navigation must expose a real focus target for its visible focus state.")
	var observed := {"track_id": "", "event_id": ""}
	timeline.track_selected.connect(func(track: Dictionary): observed.track_id = String(track.get("id", "")))
	timeline.event_selected.connect(func(event: Dictionary, track_id: String): observed.track_id = track_id; observed.event_id = String(event.get("id", "")))
	var down := InputEventKey.new()
	down.pressed = true
	down.keycode = KEY_DOWN
	timeline._gui_input(down)
	_expect(observed.track_id != "" and timeline.selected_track_id == observed.track_id and timeline.selected_event_id == "", "Down Arrow must select a timeline track without requiring a mouse.")
	var right := InputEventKey.new()
	right.pressed = true
	right.keycode = KEY_RIGHT
	timeline._gui_input(right)
	_expect(observed.event_id != "" and timeline.selected_event_id == observed.event_id, "Right Arrow must select an event on the active timeline track without requiring a mouse.")
	timeline._gui_input(down)
	_expect(timeline.selected_event_id == "", "Moving to another timeline track must clear the old event selection before keyboard inspection continues.")
	timeline._gui_input(right)
	var first_event_id := String(observed.event_id)
	timeline._gui_input(right)
	_expect(observed.event_id != first_event_id and timeline.selected_event_id == observed.event_id, "Repeated Right Arrow presses must move through events in tick order on the active track.")
	timeline.free()


func _test_explicit_compare_take_selection() -> void:
	var app := AppScript.new()
	app._ready()
	var third := TakeUtils.duplicate_take(app.spec.get_take("Take A"), app.spec.get_take_names())
	third.name = "Take C"
	var names_with_third := app.spec.get_take_names()
	names_with_third.append("Take C")
	var fourth := TakeUtils.duplicate_take(app.spec.get_take("Take B"), names_with_third)
	fourth.name = "Take D"
	app.spec.data.takes.append(third)
	app.spec.data.takes.append(fourth)
	app.current_take_name = "Take A"
	app.compare_take_name = "Take B"
	app._rebuild_workspace()
	_expect(app.compare_take_picker != null and app.compare_take_picker.item_count == 3, "A multi-take action must offer every non-primary Take as an explicit comparison target.")
	var take_d_index := -1
	if app.compare_take_picker != null:
		for index in app.compare_take_picker.item_count:
			if String(app.compare_take_picker.get_item_metadata(index)) == "Take D":
				take_d_index = index
				break
	_expect(take_d_index >= 0, "The comparison picker must include non-adjacent Takes instead of forcing the next tab.")
	if take_d_index >= 0:
		app.compare_take_picker.select(take_d_index)
		app._on_compare_take_selected(take_d_index)
		_expect(app.compare_take_name == "Take D" and app.compare_stage.take_name == "Take D", "Choosing a comparison Take must rebind the visible comparison stage to that exact Take.")
		app._on_take_tab_changed(3)
		_expect(app.current_take_name == "Take D" and app.compare_take_name != "Take D", "The comparison target must remain distinct when its Take becomes primary.")
	var single_take_3d := ActionSpecCodec.load_json("res://samples/actions/charge_3d.action.json")
	app.spec = single_take_3d.spec
	app.current_take_name = "Default"
	app.compare_take_name = "Default"
	app._populate_compare_take_picker()
	_expect(app.compare_take_picker.item_count == 1 and app.compare_take_picker.disabled and String(app.compare_take_picker.get_item_metadata(0)) == "" and app.compare_take_name == app.current_take_name, "A one-Take 3D action must show a disabled empty comparison state without inventing another version.")
	app.undo_redo.free()
	app.undo_redo = null
	app.free()


func _test_inspector_blocks_invalid_action_edits() -> void:
	var raw := _minimal_action()
	var track_result := AuthoringUtils.add_track(raw, "Default", "hitbox")
	var event_result := AuthoringUtils.add_event(track_result.data, "Default", track_result.track_id, "hitbox", 4, "2d")
	var panel := ActionInspectorPanel.new()
	panel.localization = ActionLocalization.new("en")
	panel._ready()
	panel.set_spec(ActionSpecCodec.from_dictionary(event_result.data), "Default")
	panel.inspect_event(event_result.event)
	var observed := {"event": {}}
	panel.event_changed.connect(func(event: Dictionary): observed.event = event)
	panel.payload_text.text = JSON.stringify({"shape": {"kind": "box", "offset": [0, 0, 0], "size": [1, 1, 1]}})
	panel._validate_payload()
	_expect(panel.apply_button.disabled and panel.error_label.text.contains("2D"), "Inspector must explain and block a 3D hitbox payload inside a 2D ActionSpec before Apply is pressed.")
	panel._apply_changes()
	_expect(observed.event.is_empty(), "Inspector must not emit an ActionSpec-invalid event edit that would fail only during export.")
	panel.payload_text.text = JSON.stringify({"shape": {"kind": "rect", "offset": [0, 0], "size": [64, 48]}})
	panel._validate_payload()
	_expect(not panel.apply_button.disabled and panel.error_label.text == "", "Inspector must re-enable Apply after the event payload matches the ActionSpec dimension.")
	panel.free()


func _test_ui_hierarchy_states() -> void:
	var app := AppScript.new()
	app._ready()
	app.inspector._ready()
	app.inspector.set_spec(app.spec, app.current_take_name)
	app.inspector.clear_selection()
	_expect(app.workspace_context_label.text.contains("2D Spritesheet Sword Demo") and app.dimension_label.text == "2D", "Workspace header must expose the current action and dimension without opening the project tree.")
	_expect(app.difference_button != null and not app.difference_button.disabled, "A/B header must expose an actionable first-difference control when takes differ.")
	_expect(app.delete_event_button.disabled and app.delete_track_button.disabled, "Destructive timeline controls must stay disabled until their compatible selection exists.")
	_expect(not app.inspector.fields_container.visible and app.inspector.empty_label.visible, "Inspector must show a purposeful empty state instead of editable-looking inactive fields.")
	var first_track: Dictionary = app.spec.get_take(app.current_take_name).tracks[0]
	var first_event: Dictionary = first_track.events[0]
	app._on_event_selected(first_event, String(first_track.id))
	_expect(not app.delete_event_button.disabled and not app.delete_track_button.disabled and app.inspector.fields_container.visible, "Selecting an event must reveal its editor and enable compatible delete actions.")
	_expect(app.inspector.apply_button.disabled, "Inspector apply must remain disabled until a valid field actually changes.")
	app.inspector.start_spin.value = mini(1, int(app.inspector.start_spin.max_value))
	app.inspector._validate_payload()
	_expect(not app.inspector.apply_button.disabled, "A valid inspector edit must make the apply action available.")
	var original_width := app.timeline.custom_minimum_size.x
	app.timeline.zoom(4.0)
	_expect(app.timeline.custom_minimum_size.x > original_width, "Timeline zoom must expand the scrollable canvas instead of clipping the later ticks.")
	var original_track_id := String(first_track.id)
	var changed_event := first_event.duplicate(true)
	changed_event.type = "note"
	changed_event.end_tick = changed_event.start_tick
	changed_event.payload = {"text": "Review this timing"}
	app._on_event_changed(changed_event)
	_expect(app.selected_track_id != original_track_id and String(app._find_track(app.selected_track_id).get("kind", "")) == "note", "Changing an event type must move it to a compatible semantic track.")
	app.undo_redo.undo()
	_expect(app.selected_track_id == original_track_id and String(app._find_event(String(first_event.id)).get("type", "")) == String(first_event.type), "Undoing an event type change must restore its original track and type.")
	app.undo_redo.redo()
	_expect(String(app._find_track(app.selected_track_id).get("kind", "")) == "note", "Redoing an event type change must restore the compatible destination track.")
	app.undo_redo.free()
	app.undo_redo = null
	app.free()


func _test_duplicate_take_undo_redo() -> void:
	var app := AppScript.new()
	app._ready()
	var initial_count := app.spec.get_take_names().size()
	app._duplicate_current_take()
	var duplicated_name := app.current_take_name
	_expect(app.spec.get_take_names().size() == initial_count + 1 and duplicated_name in app.spec.get_take_names(), "Duplicate Take must add one independent take through the app workflow.")
	app.undo_redo.undo()
	_expect(app.spec.get_take_names().size() == initial_count and duplicated_name not in app.spec.get_take_names(), "Undo must remove the duplicated take.")
	app.undo_redo.redo()
	_expect(app.spec.get_take_names().size() == initial_count + 1 and duplicated_name in app.spec.get_take_names(), "Redo must restore the duplicated take.")
	app.undo_redo.free()
	app.undo_redo = null
	app.free()


func _test_take_switch_rebinds_inspector_duration() -> void:
	var app := AppScript.new()
	app._ready()
	app.inspector._ready()
	app.inspector.set_spec(app.spec, app.current_take_name)
	_expect(int(app.inspector.end_spin.max_value) == 72, "Opening Take A must bind Inspector timing to its 72-tick duration.")
	app._on_take_tab_changed(1)
	_expect(app.current_take_name == "Take B" and int(app.inspector.start_spin.max_value) == 60 and int(app.inspector.end_spin.max_value) == 60, "Switching to Take B must rebind Inspector timing to its 60-tick duration.")
	app.undo_redo.free()
	app.undo_redo = null
	app.free()


func _collect_ids(take: Dictionary) -> Array[String]:
	var ids: Array[String] = [String(take.get("id", ""))]
	for marker: Variant in take.get("markers", []):
		if marker is Dictionary:
			ids.append(String(marker.get("id", "")))
	for branch: Variant in take.get("branches", []):
		if branch is Dictionary:
			ids.append(String(branch.get("id", "")))
	for track: Variant in take.get("tracks", []):
		if track is Dictionary:
			ids.append(String(track.get("id", "")))
			for event: Variant in track.get("events", []):
				if event is Dictionary:
					ids.append(String(event.get("id", "")))
	return ids


func _minimal_action() -> Dictionary:
	return {
		"schema_version": "1.0.0",
		"action_id": "minimal",
		"dimension": "2d",
		"tick_rate": 60,
		"takes": [{
			"id": "default",
			"name": "Default",
			"duration_ticks": 10,
			"markers": [],
			"branches": [],
			"tracks": [{"id": "events", "name": "Events", "kind": "game_event", "events": [
				{"id": "event-one", "type": "game_event", "start_tick": 2, "end_tick": 2, "payload": {}}
			]}]
		}]
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
