class_name ActionTimelineView
extends Control

signal event_selected(event: Dictionary, track_id: String)
signal track_selected(track: Dictionary)
signal selection_cleared()
signal seek_requested(tick: int)

const TRACK_COLORS := {
	"animation": Color("7587f5"),
	"window": Color("c98af2"),
	"hitbox": Color("ff5b68"),
	"hurtbox": Color("60b7ff"),
	"motion": Color("62d7a3"),
	"feel": Color("f3b85b"),
	"audio": Color("40c6d9"),
	"vfx": Color("40c6d9"),
	"camera": Color("f09bcb"),
	"game_event": Color("b6bfca"),
	"note": Color("7f8999"),
}

var spec: ActionSpec
var take_name := ""
var current_tick := 0
var pixels_per_tick := 9.0
var label_width := 150.0
var row_height := 38.0
var _tracks: Array = []
var _event_rects: Array[Dictionary] = []
var _track_rects: Array[Dictionary] = []
var localization: ActionLocalization
var selected_track_id := ""
var selected_event_id := ""


func set_localization(value: ActionLocalization) -> void:
	localization = value
	queue_redraw()


func set_take(value: ActionSpec, new_take_name: String) -> void:
	spec = value
	take_name = new_take_name
	_tracks = spec.get_take(take_name).get("tracks", []) if spec != null else []
	_update_minimum_size()
	queue_redraw()


func set_selection(track_id: String, event_id: String = "") -> void:
	selected_track_id = track_id
	selected_event_id = event_id
	queue_redraw()


func clear_selection() -> void:
	selected_track_id = ""
	selected_event_id = ""
	queue_redraw()


func set_tick(tick: int) -> void:
	current_tick = tick
	queue_redraw()


func zoom(delta: float) -> void:
	pixels_per_tick = clampf(pixels_per_tick + delta, 3.0, 24.0)
	_update_minimum_size()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and (event.ctrl_pressed or event.meta_pressed):
			zoom(1.0)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and (event.ctrl_pressed or event.meta_pressed):
			zoom(-1.0)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			for item: Dictionary in _event_rects:
				if item.rect.has_point(event.position):
					set_selection(String(item.track_id), String(item.event.get("id", "")))
					event_selected.emit(item.event.duplicate(true), String(item.track_id))
					return
			for item: Dictionary in _track_rects:
				if item.rect.has_point(event.position):
					set_selection(String(item.track.get("id", "")))
					track_selected.emit(item.track.duplicate(true))
					return
			if event.position.x < label_width:
				clear_selection()
				selection_cleared.emit()
				return
			var tick := maxi(0, int((event.position.x - label_width) / pixels_per_tick))
			seek_requested.emit(tick)
	elif event is InputEventKey and event.pressed and (event.ctrl_pressed or event.meta_pressed):
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			zoom(1.0)
			accept_event()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			zoom(-1.0)
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0f1218"))
	_event_rects.clear()
	_track_rects.clear()
	if spec == null:
		return
	var duration := spec.get_duration_ticks(take_name)
	_draw_ruler(duration)
	_draw_time_grid(duration)
	if _tracks.is_empty():
		var empty_text := localization.text("timeline_empty") if localization != null else "No tracks yet. Choose an event type and add a track."
		draw_string(get_theme_default_font(), Vector2(label_width + 20, 76), empty_text, HORIZONTAL_ALIGNMENT_LEFT, maxf(0.0, size.x - label_width - 40), 13, Color("98a2b3"))
	for index in _tracks.size():
		var track: Dictionary = _tracks[index]
		var y := 38.0 + index * row_height
		var track_id := String(track.get("id", ""))
		var row_rect := Rect2(0, y, size.x, row_height)
		var row_color := Color("151a23") if index % 2 == 0 else Color("121720")
		if track_id == selected_track_id:
			row_color = Color("1a2a29")
		draw_rect(row_rect, row_color)
		if track_id == selected_track_id:
			draw_rect(Rect2(0, y, label_width, row_height), Color("62d7a317"), true)
			draw_rect(Rect2(0, y, label_width, row_height), Color("62d7a3"), false, 1.0)
		var track_kind := String(track.get("kind", "note"))
		var track_color: Color = TRACK_COLORS.get(track_kind, Color("7f8999"))
		draw_rect(Rect2(0, y + 6, 3, row_height - 12), track_color, true)
		draw_string(get_theme_default_font(), Vector2(12, y + 25), String(track.get("name", "Track")), HORIZONTAL_ALIGNMENT_LEFT, label_width - 20, 13, Color("d4dae4"))
		_track_rects.append({"rect": Rect2(0, y, label_width, row_height), "track": track})
		for event: Variant in track.get("events", []):
			if event is Dictionary:
				_draw_event(event, y, track.get("kind", event.get("type", "note")), track_id)
	var playhead_x := label_width + current_tick * pixels_per_tick
	draw_line(Vector2(playhead_x, 20), Vector2(playhead_x, size.y), Color("f4f6fa"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(playhead_x - 5, 20), Vector2(playhead_x + 5, 20), Vector2(playhead_x, 28)]), Color("f4f6fa"))


func _draw_ruler(duration: int) -> void:
	draw_rect(Rect2(0, 0, size.x, 38), Color("191e28"))
	draw_line(Vector2(label_width, 0), Vector2(label_width, size.y), Color("343b49"), 1.0)
	for tick in range(0, duration + 1, 5):
		var x := label_width + tick * pixels_per_tick
		var major := tick % 10 == 0
		draw_line(Vector2(x, 24 if major else 29), Vector2(x, 38), Color("687185") if major else Color("3e4553"), 1.0)
		if major:
			draw_string(get_theme_default_font(), Vector2(x + 3, 17), str(tick), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8e98aa"))
	var tracks_label := localization.text("tracks") if localization != null else "TRACKS"
	draw_string(get_theme_default_font(), Vector2(12, 23), tracks_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9ca6b6"))
	var tick_badge := "%03d" % current_tick
	draw_rect(Rect2(label_width + current_tick * pixels_per_tick - 18, 2, 36, 18), Color("eef2f7"), true)
	draw_string(get_theme_default_font(), Vector2(label_width + current_tick * pixels_per_tick - 15, 15), tick_badge, HORIZONTAL_ALIGNMENT_CENTER, 30, 10, Color("11151d"))


func _draw_time_grid(duration: int) -> void:
	for tick in range(0, duration + 1, 10):
		var x := label_width + tick * pixels_per_tick
		draw_line(Vector2(x, 38), Vector2(x, size.y), Color("343b4975"), 1.0)


func _draw_event(event: Dictionary, y: float, fallback_kind: String, track_id: String) -> void:
	var start := int(event.get("start_tick", 0))
	var finish := int(event.get("end_tick", start))
	var width := maxf(7.0, (finish - start + 1) * pixels_per_tick - 2.0)
	var rect := Rect2(label_width + start * pixels_per_tick + 1, y + 5, width, row_height - 10)
	var kind := String(event.get("type", fallback_kind))
	var color: Color = TRACK_COLORS.get(kind, Color("7f8999"))
	var is_selected := String(event.get("id", "")) == selected_event_id
	draw_rect(rect, color.darkened(0.36 if is_selected else 0.5), true)
	draw_rect(rect, Color("f4f6fa") if is_selected else color, false, 2.0 if is_selected else 1.0)
	var label := String(event.get("payload", {}).get("kind", event.get("payload", {}).get("clip", kind))).capitalize()
	draw_string(get_theme_default_font(), rect.position + Vector2(6, 19), label, HORIZONTAL_ALIGNMENT_LEFT, maxf(0, rect.size.x - 12), 12, color.lightened(0.28))
	_event_rects.append({"rect": rect, "event": event, "track_id": track_id})


func _update_minimum_size() -> void:
	var duration := spec.get_duration_ticks(take_name) if spec != null and take_name != "" else 0
	custom_minimum_size = Vector2(maxf(760.0, label_width + duration * pixels_per_tick + 36.0), 38.0 + maxi(1, _tracks.size()) * row_height)
