class_name PreviewStage2D
extends Control

signal outcome_requested(event_id: String, outcome: String)

var spec: ActionSpec
var take_name := ""
var current_tick := 0
var show_hitboxes := true
var show_trajectory := true
var _events: Array[Dictionary] = []
var _hitbox_event: Dictionary = {}
var _motion_offset := Vector2.ZERO
var _impact_flash := 0.0
var branch_notice := ""
var imported_texture: Texture2D
var imported_asset: Dictionary = {}
var localization: ActionLocalization
var is_comparison := false


func set_comparison_style(value: bool) -> void:
	is_comparison = value
	queue_redraw()


func set_localization(value: ActionLocalization) -> void:
	localization = value
	queue_redraw()


func set_take(value: ActionSpec, new_take_name: String) -> void:
	spec = value
	take_name = new_take_name
	_events.clear()
	if spec != null:
		var take := spec.get_take(take_name)
		for track: Variant in take.get("tracks", []):
			if track is Dictionary:
				for event: Variant in track.get("events", []):
					if event is Dictionary:
						_events.append(event)
	current_tick = 0
	queue_redraw()


func set_tick(tick: int) -> void:
	current_tick = tick
	_hitbox_event = {}
	_motion_offset = Vector2.ZERO
	_impact_flash = 0.0
	for event: Dictionary in _events:
		var start := int(event.get("start_tick", 0))
		var finish := int(event.get("end_tick", start))
		if event.get("type") == "motion" and start <= current_tick:
			var delta: Array = event.get("payload", {}).get("delta", [0, 0])
			if delta.size() >= 2:
				_motion_offset += Vector2(float(delta[0]), float(delta[1]))
		if start <= current_tick and current_tick <= finish:
			if event.get("type") == "hitbox":
				_hitbox_event = event
			elif event.get("type") == "feel" and event.get("payload", {}).get("kind") == "hit_stop":
				_impact_flash = 1.0
	queue_redraw()


func set_branch_notice(message: String) -> void:
	branch_notice = message
	queue_redraw()


func bind_project_assets(asset_root: String) -> void:
	imported_texture = null
	imported_asset = {}
	if spec == null:
		return
	for asset: Variant in spec.data.get("assets", []):
		if asset is Dictionary and asset.get("kind") == "image":
			var path := asset_root.path_join(String(asset.get("path", ""))).simplify_path()
			if path.begins_with("res://") and ResourceLoader.exists(path):
				var resource := ResourceLoader.load(path)
				if resource is Texture2D:
					imported_texture = resource
			else:
				var image := Image.new()
				if image.load(path) == OK:
					imported_texture = ImageTexture.create_from_image(image)
			if imported_texture != null:
				imported_asset = asset.duplicate(true)
				break
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _hitbox_event.is_empty():
		outcome_requested.emit(String(_hitbox_event.get("id", "")), "hit" if event.button_index == MOUSE_BUTTON_LEFT else "block")


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color("0b1017"))
	var header_height := 46.0
	var footer_height := 32.0
	var accent := Color("f3b85b") if is_comparison else Color("62d7a3")
	draw_rect(Rect2(0, 0, size.x, header_height), Color("181f2a"))
	draw_rect(Rect2(0, header_height - 2, size.x, 2), accent.darkened(0.12))
	var stage_area := Rect2(0, header_height, size.x, maxf(0.0, size.y - header_height - footer_height))
	_draw_grid(stage_area)
	var ground_y := size.y * 0.76
	draw_rect(Rect2(0, ground_y, size.x, maxf(0.0, size.y - footer_height - ground_y)), Color("0e151d"), true)
	draw_line(Vector2(0, ground_y), Vector2(size.x, ground_y), Color("5c687a"), 2.0)
	draw_line(Vector2(0, ground_y + 5), Vector2(size.x, ground_y + 5), Color("1e2835"), 1.0)
	var hero := Vector2(size.x * 0.3, ground_y - 72) + _motion_offset
	var target := Vector2(size.x * 0.72, ground_y - 66)
	if show_trajectory:
		draw_dashed_line(Vector2(size.x * 0.3, ground_y - 4), hero + Vector2(0, 66), Color("62d7a3"), 2.0, 9.0)
	_draw_actor(hero, Color("62d7a3"), localization.text("performer") if localization != null else "PERFORMER")
	_draw_actor(target, Color("f3b85b"), localization.text("target") if localization != null else "TARGET")
	if show_hitboxes and not _hitbox_event.is_empty():
		_draw_hitbox(hero, _hitbox_event)
	if _impact_flash > 0.0:
		draw_circle(target + Vector2(0, -22), 54.0, Color(1.0, 0.78, 0.32, 0.16))
	var role := "COMPARE" if is_comparison else "PRIMARY"
	if localization != null:
		role = localization.text("comparison_take") if is_comparison else localization.text("primary_take")
	draw_string(get_theme_default_font(), Vector2(16, 18), role, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent.lightened(0.1))
	draw_string(get_theme_default_font(), Vector2(16, 36), take_name, HORIZONTAL_ALIGNMENT_LEFT, maxf(0.0, size.x * 0.58), 15, Color("eef2f7"))
	var tick_label := "%03d / %03d" % [current_tick, spec.get_duration_ticks(take_name) if spec else 0]
	draw_string(get_theme_default_font(), Vector2(size.x - 126, 31), tick_label, HORIZONTAL_ALIGNMENT_RIGHT, 110, 13, Color("c9d1dd"))
	draw_rect(Rect2(0, size.y - footer_height, size.x, footer_height), Color("0d1118"))
	var help := localization.text("hit_help") if localization != null else "Left click active hitbox: HIT  ·  Right click: BLOCK"
	draw_string(get_theme_default_font(), Vector2(16, size.y - 11), help, HORIZONTAL_ALIGNMENT_LEFT, maxf(0.0, size.x - 32), 12, Color("aab4c4"))


func _draw_grid(area: Rect2) -> void:
	var step := 40.0
	var color := Color(0.22, 0.27, 0.35, 0.24)
	var x := 0.0
	var column := 0
	while x <= area.size.x:
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), color.lightened(0.16) if column % 4 == 0 else color, 1.0)
		x += step
		column += 1
	var y := area.position.y
	var row := 0
	while y <= area.end.y:
		draw_line(Vector2(0, y), Vector2(area.size.x, y), color.lightened(0.16) if row % 3 == 0 else color, 1.0)
		y += step
		row += 1


func _draw_actor(center: Vector2, color: Color, role: String) -> void:
	var performer_role := localization.text("performer") if localization != null else "PERFORMER"
	var target_role := localization.text("target") if localization != null else "TARGET"
	if role == performer_role and imported_texture != null:
		var source_rect := _sprite_source_rect()
		var image_height := 238.0
		var image_width := image_height * source_rect.size.x / maxf(1.0, source_rect.size.y)
		var image_rect := Rect2(center + Vector2(-image_width * 0.5, 82.0 - image_height), Vector2(image_width, image_height))
		draw_texture_rect_region(imported_texture, image_rect, source_rect)
		draw_string(get_theme_default_font(), center + Vector2(-46, 104), role, HORIZONTAL_ALIGNMENT_CENTER, 92, 10, color.lightened(0.18))
		if branch_notice != "":
			draw_string(get_theme_default_font(), Vector2(16, 50), branch_notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f3b85b"))
		return
	if role == target_role:
		_draw_training_dummy(center, color, role)
		return
	draw_circle(center + Vector2(0, -38), 18.0, color.darkened(0.18))
	draw_rect(Rect2(center + Vector2(-18, -18), Vector2(36, 62)), color, true)
	draw_line(center + Vector2(-12, 44), center + Vector2(-22, 69), color, 8.0)
	draw_line(center + Vector2(12, 44), center + Vector2(22, 69), color, 8.0)
	draw_string(get_theme_default_font(), center + Vector2(-38, 88), role, HORIZONTAL_ALIGNMENT_CENTER, 76, 10, color.lightened(0.18))
	if role == performer_role and branch_notice != "":
		draw_string(get_theme_default_font(), Vector2(16, 50), branch_notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f3b85b"))


func _draw_training_dummy(center: Vector2, color: Color, role: String) -> void:
	var dark := Color("171d27")
	draw_circle(center + Vector2(0, -54), 18.0, color.darkened(0.08))
	draw_circle(center + Vector2(0, -54), 13.0, dark)
	var torso := PackedVector2Array([
		center + Vector2(-25, -30), center + Vector2(25, -30),
		center + Vector2(20, 31), center + Vector2(-20, 31),
	])
	draw_colored_polygon(torso, color.darkened(0.12))
	draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[0]]), color.lightened(0.08), 2.0)
	draw_circle(center + Vector2(0, -2), 13.0, dark)
	draw_circle(center + Vector2(0, -2), 8.0, color.lightened(0.14), false, 2.0)
	draw_line(center + Vector2(-20, -17), center + Vector2(-38, 16), color, 8.0)
	draw_line(center + Vector2(20, -17), center + Vector2(38, 16), color, 8.0)
	draw_line(center + Vector2(0, 31), center + Vector2(0, 62), color.darkened(0.18), 9.0)
	draw_rect(Rect2(center + Vector2(-34, 60), Vector2(68, 9)), color.darkened(0.25), true)
	draw_string(get_theme_default_font(), center + Vector2(-46, 89), role, HORIZONTAL_ALIGNMENT_CENTER, 92, 10, color.lightened(0.18))


func _sprite_source_rect() -> Rect2:
	var texture_size := imported_texture.get_size() if imported_texture != null else Vector2.ONE
	var layout: Dictionary = imported_asset.get("layout", {})
	var columns := maxi(1, int(layout.get("columns", 1)))
	var rows := maxi(1, int(layout.get("rows", 1)))
	var frame_count := maxi(1, int(imported_asset.get("frame_count", columns * rows)))
	var frame_index := _sprite_frame_index(frame_count)
	var frame_size := Vector2(texture_size.x / columns, texture_size.y / rows)
	var column := frame_index % columns
	var row := frame_index / columns
	return Rect2(Vector2(column, row) * frame_size, frame_size)


func _sprite_frame_index(frame_count: int = -1) -> int:
	if frame_count <= 0:
		frame_count = maxi(1, int(imported_asset.get("frame_count", 1)))
	var animation_event: Dictionary = {}
	for event: Dictionary in _events:
		if event.get("type") == "animation":
			animation_event = event
			break
	if animation_event.is_empty():
		return 0
	var start := int(animation_event.get("start_tick", 0))
	var finish := maxi(start, int(animation_event.get("end_tick", start)))
	var duration := maxi(1, finish - start + 1)
	var speed := maxf(0.01, float(animation_event.get("payload", {}).get("speed", 1.0)))
	var progress := clampf(float(current_tick - start) / duration * speed, 0.0, 0.999999)
	return clampi(int(floor(progress * frame_count)), 0, frame_count - 1)


func _draw_hitbox(hero: Vector2, event: Dictionary) -> void:
	var shape: Dictionary = event.get("payload", {}).get("shape", {})
	var offset: Array = shape.get("offset", [70, 0])
	var dimensions: Array = shape.get("size", [110, 60])
	var rect := Rect2(hero + Vector2(float(offset[0]), float(offset[1])) - Vector2(float(dimensions[0]), float(dimensions[1])) * 0.5, Vector2(float(dimensions[0]), float(dimensions[1])))
	draw_rect(rect, Color(0.98, 0.25, 0.32, 0.24), true)
	draw_rect(rect, Color("ff5b68"), false, 2.0)
	var hitbox_label := localization.text("hitbox") if localization != null else "HITBOX"
	draw_string(get_theme_default_font(), rect.position + Vector2(4, -5), hitbox_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ff7b85"))
