class_name PreviewStage3D
extends SubViewportContainer

var spec: ActionSpec
var take_name := ""
var current_tick := 0
var viewport_3d: SubViewport
var world_root: Node3D
var performer: MeshInstance3D
var target: MeshInstance3D
var hitbox: MeshInstance3D
var camera: Camera3D
var _events: Array[Dictionary] = []
var _base_position := Vector3(-1.5, 0.8, 1.2)
var imported_model: Node3D
var branch_label: Label
var header_background: ColorRect
var role_label: Label
var take_label: Label
var tick_label: Label
var imported_animation_players: Array[AnimationPlayer] = []
var _active_animation_signature := ""
var localization: ActionLocalization
var is_comparison := false


func _ready() -> void:
	stretch = true
	viewport_3d = SubViewport.new()
	viewport_3d.name = "Rehearsal3D"
	viewport_3d.own_world_3d = true
	viewport_3d.transparent_bg = false
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport_3d)
	header_background = ColorRect.new()
	header_background.position = Vector2.ZERO
	header_background.size = Vector2(size.x, 44)
	header_background.color = Color("171d27")
	header_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_background)
	role_label = Label.new()
	role_label.position = Vector2(16, 5)
	role_label.add_theme_font_size_override("font_size", 10)
	role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(role_label)
	take_label = Label.new()
	take_label.position = Vector2(16, 18)
	take_label.add_theme_font_size_override("font_size", 15)
	take_label.add_theme_color_override("font_color", Color("eef2f7"))
	take_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(take_label)
	tick_label = Label.new()
	tick_label.position = Vector2(size.x - 130, 14)
	tick_label.size = Vector2(114, 22)
	tick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tick_label.add_theme_font_size_override("font_size", 13)
	tick_label.add_theme_color_override("font_color", Color("c9d1dd"))
	tick_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tick_label)
	branch_label = Label.new()
	branch_label.position = Vector2(16, 52)
	branch_label.add_theme_color_override("font_color", Color("f3b85b"))
	branch_label.add_theme_font_size_override("font_size", 12)
	branch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(branch_label)
	world_root = Node3D.new()
	viewport_3d.add_child(world_root)
	_build_world()
	resized.connect(_resize_viewport)
	_resize_viewport()
	_update_header()


func set_localization(value: ActionLocalization) -> void:
	localization = value
	_update_header()


func set_comparison_style(value: bool) -> void:
	is_comparison = value
	_update_header()


func set_take(value: ActionSpec, new_take_name: String) -> void:
	spec = value
	take_name = new_take_name
	_events.clear()
	if spec != null:
		for track: Variant in spec.get_take(take_name).get("tracks", []):
			if track is Dictionary:
				for event: Variant in track.get("events", []):
					if event is Dictionary:
						_events.append(event)
	set_tick(0)
	_update_header()


func set_tick(tick: int) -> void:
	current_tick = tick
	_update_header()
	if performer == null:
		return
	performer.position = _base_position
	hitbox.visible = false
	for event: Dictionary in _events:
		var start := int(event.get("start_tick", 0))
		var finish := int(event.get("end_tick", start))
		if event.get("type") == "motion" and start <= tick:
			var delta: Array = event.get("payload", {}).get("delta", [0, 0, 0])
			if delta.size() >= 3:
				performer.position += Vector3(float(delta[0]), float(delta[1]), float(delta[2]))
		if event.get("type") == "hitbox" and start <= tick and tick <= finish:
			hitbox.visible = true
			var shape: Dictionary = event.get("payload", {}).get("shape", {})
			var offset: Array = shape.get("offset", [0, 1, -0.8])
			var dimensions: Array = shape.get("size", [1, 1, 1])
			hitbox.position = performer.position + Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
			hitbox.scale = Vector3(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]))
	if imported_model != null and is_instance_valid(imported_model):
		imported_model.position = performer.position
	_sync_imported_animation(tick)


func set_branch_notice(message: String) -> void:
	if branch_label != null:
		branch_label.text = message


func bind_project_assets(asset_root: String) -> void:
	if spec == null:
		return
	if imported_model != null and is_instance_valid(imported_model):
		imported_model.queue_free()
	imported_model = null
	imported_animation_players.clear()
	_active_animation_signature = ""
	for asset: Variant in spec.data.get("assets", []):
		if not asset is Dictionary or asset.get("kind") != "model":
			continue
		var path := asset_root.path_join(String(asset.get("path", "")))
		var loaded := ActionModelImporter.load_scene(path)
		if loaded.ok:
			imported_model = loaded.scene
			performer.visible = int(loaded.metadata.get("mesh_count", 0)) == 0
			imported_model.position = _base_position
			imported_model.scale = Vector3.ONE * 1.22
			world_root.add_child(imported_model)
			_collect_animation_players(imported_model)
			set_tick(current_tick)
			break


func _collect_animation_players(root: Node) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is AnimationPlayer:
			imported_animation_players.append(node)
		for child in node.get_children():
			if child is Node:
				stack.append(child)


func _sync_imported_animation(tick: int) -> void:
	if imported_animation_players.is_empty():
		return
	var active: Dictionary = {}
	for event: Dictionary in _events:
		if event.get("type") != "animation":
			continue
		var start := int(event.get("start_tick", 0))
		var finish := int(event.get("end_tick", start))
		if start <= tick and tick <= finish:
			active = event
			break
	if active.is_empty():
		_active_animation_signature = ""
		for player in imported_animation_players:
			player.stop()
		return
	var payload: Dictionary = active.get("payload", {})
	var requested_clip := String(payload.get("clip", ""))
	var speed := maxf(0.001, absf(float(payload.get("speed", 1.0))))
	var reverse := bool(payload.get("reverse", false))
	var elapsed := maxf(0.0, float(tick - int(active.get("start_tick", 0))) / 60.0 * speed)
	for player in imported_animation_players:
		var clip := _resolve_clip(player, requested_clip)
		if clip == "":
			continue
		var animation := player.get_animation(clip)
		var seek_time := clampf(animation.length - elapsed if reverse else elapsed, 0.0, animation.length)
		var signature := "%s:%s" % [player.get_instance_id(), clip]
		if _active_animation_signature != signature or player.current_animation != clip:
			player.play(clip, float(payload.get("blend", -1.0)), 0.0)
		player.seek(seek_time, true, true)
		_active_animation_signature = signature


func _resolve_clip(player: AnimationPlayer, requested: String) -> String:
	if requested != "" and player.has_animation(requested):
		return requested
	var requested_lower := requested.to_lower()
	for candidate: StringName in player.get_animation_list():
		var name := String(candidate)
		if name != "RESET" and requested_lower != "" and _has_clip_suffix(name.to_lower(), requested_lower):
			return name
	for candidate: StringName in player.get_animation_list():
		var name := String(candidate)
		if name != "RESET" and requested_lower != "" and (name.to_lower().contains(requested_lower) or requested_lower.contains(name.to_lower())):
			return name
	for candidate: StringName in player.get_animation_list():
		if String(candidate) != "RESET":
			return String(candidate)
	return ""


func _has_clip_suffix(candidate_lower: String, requested_lower: String) -> bool:
	if candidate_lower == requested_lower:
		return true
	for separator: String in ["|", ":", "/", "\\", "_", "-", ".", " "]:
		if candidate_lower.ends_with(separator + requested_lower):
			return true
	return false


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color("090e15")
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color("c8d7eb")
	environment_resource.ambient_light_energy = 0.58
	environment.environment = environment_resource
	world_root.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -34, 0)
	light.light_color = Color("dbe8ff")
	light.light_energy = 1.65
	world_root.add_child(light)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2.4, 3.1, 1.7)
	rim.light_color = Color("62d7a3")
	rim.light_energy = 2.6
	rim.omni_range = 5.5
	world_root.add_child(rim)
	var target_light := OmniLight3D.new()
	target_light.position = Vector3(0.8, 2.2, -3.0)
	target_light.light_color = Color("f3b85b")
	target_light.light_energy = 2.0
	target_light.omni_range = 4.0
	world_root.add_child(target_light)
	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(10, 0.12, 8)
	ground.mesh = ground_mesh
	ground.position = Vector3(0, -0.06, 0)
	ground.material_override = _material(Color("202938"))
	world_root.add_child(ground)
	_add_stage_marker(Vector3(-1.5, 0.012, 1.0), Color("62d7a3"))
	_add_stage_marker(Vector3(0, 0.014, -3.0), Color("f3b85b"))
	performer = MeshInstance3D.new()
	var performer_mesh := CapsuleMesh.new()
	performer_mesh.radius = 0.48
	performer_mesh.height = 1.6
	performer.mesh = performer_mesh
	performer.position = _base_position
	performer.material_override = _material(Color("62d7a3"))
	world_root.add_child(performer)
	target = MeshInstance3D.new()
	var target_mesh := CapsuleMesh.new()
	target_mesh.radius = 0.5
	target_mesh.height = 1.7
	target.mesh = target_mesh
	target.position = Vector3(0, 0.85, -3.0)
	target.material_override = _material(Color("f3b85b"))
	world_root.add_child(target)
	hitbox = MeshInstance3D.new()
	hitbox.mesh = BoxMesh.new()
	var hitbox_material := _material(Color(1.0, 0.18, 0.24, 0.35))
	hitbox_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hitbox_material.emission_enabled = true
	hitbox_material.emission = Color("ff3347")
	hitbox_material.emission_energy_multiplier = 1.8
	hitbox.material_override = hitbox_material
	hitbox.visible = false
	world_root.add_child(hitbox)
	camera = Camera3D.new()
	camera.position = Vector3(7.2, 4.6, 8.2)
	camera.fov = 50.0
	camera.look_at_from_position(camera.position, Vector3(-0.2, 1.55, -1.2))
	world_root.add_child(camera)


func _add_stage_marker(position: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.82
	mesh.bottom_radius = 0.82
	mesh.height = 0.025
	marker.mesh = mesh
	marker.position = position
	var marker_material := _material(Color(color, 0.18))
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_material.emission_enabled = true
	marker_material.emission = color
	marker_material.emission_energy_multiplier = 0.55
	marker.material_override = marker_material
	world_root.add_child(marker)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	return material


func _resize_viewport() -> void:
	# SubViewportContainer owns viewport sizing while stretch is enabled.
	if header_background != null:
		header_background.size = Vector2(size.x, 44)
	if tick_label != null:
		tick_label.position.x = maxf(16.0, size.x - 130.0)


func _update_header() -> void:
	if role_label == null:
		return
	var accent := Color("f3b85b") if is_comparison else Color("62d7a3")
	role_label.text = "COMPARE" if is_comparison else "PRIMARY"
	if localization != null:
		role_label.text = localization.text("comparison_take") if is_comparison else localization.text("primary_take")
	role_label.add_theme_color_override("font_color", accent.lightened(0.1))
	take_label.text = take_name
	tick_label.text = "%03d / %03d" % [current_tick, spec.get_duration_ticks(take_name) if spec != null else 0]
	header_background.color = Color("1d1b18") if is_comparison else Color("151f1d")
