extends Control

# THESIS: timing differences are the product; the interface refuses a dashboard and keeps A/B rehearsal, events, and the playhead visible together.
# OWN-WORLD: Godot Modern charcoal surfaces, restrained green focus, semantic track colors, square editorial panels, and dense native controls.
# STORY: open a working action, rehearse two takes, inspect the first meaningful difference, edit an event, and export the same contract to Godot.
# FIRST VIEWPORT: project tree left, paired rehearsal stages center, event inspector right, transport above, and a full-width multitrack timeline below.
# FORM: familiar desktop editor extended by a paired rehearsal desk; seed key action-director-native-workbench. FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md

const SAMPLE_2D := "res://samples/actions/sword_strike.action.json"
const SAMPLE_3D := "res://samples/actions/charge_3d.action.json"
const AUTOSAVE_PATH := "user://recovery.action.json"
const SETTINGS_PATH := "user://action_director_settings.json"

var spec: ActionSpec
var project_data: Dictionary = {}
var action_path := ""
var project_path := ""
var current_take_name := ""
var compare_take_name := ""
var current_tick := 0
var is_playing := false
var compare_enabled := true
var undo_redo := UndoRedo.new()
var _last_autosave_msec := 0
var _preview_accumulator := 0.0
var primary_runtime: ActionDirectorPlayer
var compare_runtime: ActionDirectorPlayer

var project_tree: Tree
var take_tabs: TabBar
var compare_take_picker: OptionButton
var primary_stage_holder: PanelContainer
var compare_stage_holder: PanelContainer
var primary_stage: Control
var compare_stage: Control
var timeline: ActionTimelineView
var inspector: ActionInspectorPanel
var status_label: Label
var time_label: Label
var comparison_label: Label
var workspace_context_label: Label
var dimension_label: Label
var timeline_selection_label: Label
var play_button: Button
var compare_button: Button
var difference_button: Button
var delete_event_button: Button
var delete_track_button: Button
var file_dialog: FileDialog
var asset_dialog: FileDialog
var export_dialog: FileDialog
var project_dialog: FileDialog
var autosave_timer: Timer
var localization: ActionLocalization
var language_picker: OptionButton
var localized_controls: Dictionary = {}
var localized_tooltips: Dictionary = {}
var tutorial_center: ActionTutorialCenter
var manual_window: ActionManualWindow
var tutorial_completed: Array[String] = []
var first_run_pending := false
var event_type_picker: OptionButton
var selected_track_id := ""
var selected_event_id := ""


func _ready() -> void:
	var settings := _load_settings()
	localization = ActionLocalization.new(String(settings.get("locale", OS.get_locale())))
	for chapter_id: Variant in settings.get("tutorial_completed", []):
		var normalized_id := String(chapter_id)
		if normalized_id in ActionTutorialCatalog.CHAPTER_IDS and normalized_id not in tutorial_completed:
			tutorial_completed.append(normalized_id)
	first_run_pending = not bool(settings.get("tutorial_seen", false))
	_build_interface()
	_open_action(SAMPLE_2D)
	if first_run_pending:
		call_deferred("_show_first_run_tutorial")


func _exit_tree() -> void:
	if undo_redo != null:
		undo_redo.free()
		undo_redo = null


func _process(delta: float) -> void:
	if is_playing and spec != null:
		_preview_accumulator += delta
		var tick_seconds := 1.0 / 60.0
		while _preview_accumulator >= tick_seconds and is_playing:
			_preview_accumulator -= tick_seconds
			if primary_runtime != null and primary_runtime.is_active:
				primary_runtime.advance_one_tick()
			if compare_runtime != null and compare_runtime.is_active:
				compare_runtime.advance_one_tick()
			_sync_stages_from_runtime()
			var primary_done := primary_runtime == null or not primary_runtime.is_active
			var compare_done := not compare_enabled or compare_runtime == null or not compare_runtime.is_active
			if primary_done and compare_done:
				is_playing = false
				play_button.text = localization.text("play")
	if Time.get_ticks_msec() - _last_autosave_msec > 30000:
		_autosave()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("play_pause"):
		_toggle_playback()
	elif event.is_action_pressed("step_back"):
		_set_tick(current_tick - 1)
	elif event.is_action_pressed("step_forward"):
		_set_tick(current_tick + 1)
	elif event.is_action_pressed("reset_preview"):
		_set_tick(0)
	elif event.is_action_pressed("toggle_compare"):
		_toggle_compare()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		if selected_event_id != "":
			_delete_selected_event()
		elif selected_track_id != "":
			_delete_selected_track()
	elif event is InputEventKey and event.ctrl_pressed and event.pressed:
		if event.shift_pressed and event.keycode == KEY_Z:
			undo_redo.redo()
		elif event.keycode == KEY_Z:
			undo_redo.undo()
		elif event.keycode == KEY_Y:
			undo_redo.redo()
		elif event.keycode == KEY_S:
			_save_project()
	elif event is InputEventKey and event.meta_pressed and event.pressed:
		if event.shift_pressed and event.keycode == KEY_Z:
			undo_redo.redo()
		elif event.keycode == KEY_Z:
			undo_redo.undo()
		elif event.keycode == KEY_S:
			_save_project()


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("0f1218")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_top_bar())
	var main_split := HSplitContainer.new()
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.split_offset = 250
	root.add_child(main_split)
	main_split.add_child(_build_left_panel())
	var center_right := HSplitContainer.new()
	center_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_right.split_offset = -310
	main_split.add_child(center_right)
	center_right.add_child(_build_center())
	center_right.add_child(_build_inspector())
	root.add_child(_build_status_bar())
	_build_dialogs()


func _build_top_bar() -> Control:
	var bar := MarginContainer.new()
	bar.custom_minimum_size.y = 94
	bar.add_theme_constant_override("margin_left", 14)
	bar.add_theme_constant_override("margin_right", 14)
	bar.add_theme_constant_override("margin_top", 7)
	bar.add_theme_constant_override("margin_bottom", 7)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	bar.add_child(stack)
	var identity_row := HBoxContainer.new()
	identity_row.custom_minimum_size.y = 31
	identity_row.add_theme_constant_override("separation", 9)
	stack.add_child(identity_row)
	var title := Label.new()
	title.text = "ACTION DIRECTOR"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("f1f4f8"))
	identity_row.add_child(title)
	var alpha := Label.new()
	alpha.text = "ALPHA"
	alpha.theme_type_variation = "StatusLabel"
	alpha.tooltip_text = localization.text("alpha_status_tip")
	identity_row.add_child(alpha)
	identity_row.add_child(_v_separator())
	workspace_context_label = Label.new()
	workspace_context_label.text = localization.text("workspace_loading")
	workspace_context_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	workspace_context_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace_context_label.add_theme_color_override("font_color", Color("aeb7c6"))
	identity_row.add_child(workspace_context_label)
	identity_row.add_child(_localized_button("tutorial", _show_tutorial_center, "tip_tutorial"))
	language_picker = OptionButton.new()
	language_picker.custom_minimum_size.x = 116
	language_picker.tooltip_text = localization.text("language")
	for locale: String in ActionLocalization.SUPPORTED_LOCALES:
		language_picker.add_item(ActionLocalization.LOCALE_NAMES[locale])
		language_picker.set_item_metadata(language_picker.item_count - 1, locale)
		if locale == localization.locale:
			language_picker.select(language_picker.item_count - 1)
	language_picker.item_selected.connect(_on_language_selected)
	identity_row.add_child(language_picker)
	var command_row := HBoxContainer.new()
	command_row.custom_minimum_size.y = 42
	command_row.add_theme_constant_override("separation", 6)
	stack.add_child(command_row)
	command_row.add_child(_localized_button("open", _show_open_dialog, "tip_open"))
	command_row.add_child(_localized_button("import", _show_asset_dialog, "tip_import"))
	command_row.add_child(_localized_button("save", _save_project, "tip_save"))
	var export_button := _localized_button("export", _show_export_dialog, "tip_export")
	export_button.theme_type_variation = "PrimaryButton"
	command_row.add_child(export_button)
	command_row.add_child(_localized_button("recover", _recover_autosave, "tip_recover"))
	command_row.add_child(_v_separator())
	command_row.add_child(_localized_button("undo", undo_redo.undo, "tip_undo"))
	command_row.add_child(_localized_button("redo", undo_redo.redo, "tip_redo"))
	command_row.add_spacer(false)
	command_row.add_child(_localized_button("step_back", func(): _set_tick(current_tick - 1), "tip_step_back"))
	play_button = _localized_button("play", _toggle_playback, "tip_play")
	play_button.theme_type_variation = "TransportButton"
	play_button.custom_minimum_size.x = 78
	command_row.add_child(play_button)
	command_row.add_child(_localized_button("step_forward", func(): _set_tick(current_tick + 1), "tip_step_forward"))
	command_row.add_child(_localized_button("reset", func(): _set_tick(0), "tip_reset"))
	command_row.add_child(_v_separator())
	compare_button = _localized_button("compare_on", _toggle_compare, "tip_compare_on")
	compare_button.toggle_mode = true
	compare_button.button_pressed = true
	compare_button.theme_type_variation = "CompareButton"
	command_row.add_child(compare_button)
	return bar


func _build_left_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 250
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var heading := Label.new()
	heading.text = localization.text("project")
	localized_controls["project"] = heading
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color("aeb7c6"))
	var project_header := HBoxContainer.new()
	project_header.add_child(heading)
	project_header.add_spacer(false)
	dimension_label = Label.new()
	dimension_label.theme_type_variation = "StatusLabel"
	dimension_label.text = "2D"
	project_header.add_child(dimension_label)
	column.add_child(project_header)
	project_tree = Tree.new()
	project_tree.hide_root = true
	project_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	project_tree.item_selected.connect(_on_tree_selected)
	column.add_child(project_tree)
	var sample_label := Label.new()
	sample_label.text = localization.text("samples")
	localized_controls["samples"] = sample_label
	sample_label.add_theme_font_size_override("font_size", 11)
	sample_label.add_theme_color_override("font_color", Color("8f99aa"))
	column.add_child(sample_label)
	var sample_row := HBoxContainer.new()
	sample_row.add_theme_constant_override("separation", 6)
	var sample_2d := _localized_button("sample_2d_short", func(): _open_action(SAMPLE_2D))
	sample_2d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sample_2d.tooltip_text = localization.text("open_2d_sample")
	localized_tooltips["open_2d_sample"] = sample_2d
	var sample_3d := _localized_button("sample_3d_short", func(): _open_action(SAMPLE_3D))
	sample_3d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sample_3d.tooltip_text = localization.text("open_3d_sample")
	localized_tooltips["open_3d_sample"] = sample_3d
	sample_row.add_child(sample_2d)
	sample_row.add_child(sample_3d)
	column.add_child(sample_row)
	return panel


func _build_center() -> Control:
	var vertical := VSplitContainer.new()
	vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vertical.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical.split_offset = 500
	var upper := VBoxContainer.new()
	upper.add_theme_constant_override("separation", 6)
	vertical.add_child(upper)
	var take_stack := VBoxContainer.new()
	take_stack.add_theme_constant_override("separation", 4)
	var take_row := HBoxContainer.new()
	var rehearsal_label := Label.new()
	rehearsal_label.text = localization.text("rehearsal")
	localized_controls["rehearsal"] = rehearsal_label
	rehearsal_label.add_theme_font_size_override("font_size", 12)
	rehearsal_label.add_theme_color_override("font_color", Color("aeb7c6"))
	take_row.add_child(rehearsal_label)
	take_row.add_child(_v_separator())
	take_tabs = TabBar.new()
	take_tabs.custom_minimum_size.x = 210
	take_tabs.tab_changed.connect(_on_take_tab_changed)
	take_row.add_child(take_tabs)
	var compare_with_label := Label.new()
	compare_with_label.text = localization.text("compare_with")
	compare_with_label.add_theme_color_override("font_color", Color("aeb7c6"))
	localized_controls["compare_with"] = compare_with_label
	take_row.add_child(compare_with_label)
	compare_take_picker = OptionButton.new()
	compare_take_picker.custom_minimum_size.x = 150
	compare_take_picker.tooltip_text = localization.text("tip_compare_take")
	compare_take_picker.item_selected.connect(_on_compare_take_selected)
	localized_tooltips["tip_compare_take"] = compare_take_picker
	take_row.add_child(compare_take_picker)
	take_row.add_spacer(false)
	var duplicate_button := _localized_button("duplicate_take", _duplicate_current_take, "tip_duplicate_take")
	take_row.add_child(duplicate_button)
	take_stack.add_child(take_row)
	var comparison_row := HBoxContainer.new()
	comparison_label = Label.new()
	comparison_label.text = localization.text("no_comparison")
	comparison_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	comparison_label.add_theme_color_override("font_color", Color("c2cad7"))
	comparison_row.add_child(comparison_label)
	difference_button = _localized_button("jump_to_difference", _jump_to_first_difference, "tip_jump_to_difference")
	difference_button.disabled = true
	comparison_row.add_child(difference_button)
	take_stack.add_child(comparison_row)
	upper.add_child(take_stack)
	var stage_split := HSplitContainer.new()
	stage_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_split.split_offset = 0
	upper.add_child(stage_split)
	primary_stage_holder = PanelContainer.new()
	primary_stage_holder.theme_type_variation = "TakeAStage"
	primary_stage_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_split.add_child(primary_stage_holder)
	compare_stage_holder = PanelContainer.new()
	compare_stage_holder.theme_type_variation = "TakeBStage"
	compare_stage_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_split.add_child(compare_stage_holder)
	var timeline_area := VBoxContainer.new()
	timeline_area.add_theme_constant_override("separation", 0)
	vertical.add_child(timeline_area)
	timeline_area.add_child(_build_timeline_toolbar())
	var timeline_scroll := ScrollContainer.new()
	timeline_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	timeline_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	timeline_area.add_child(timeline_scroll)
	timeline = ActionTimelineView.new()
	timeline.set_localization(localization)
	timeline.focus_mode = Control.FOCUS_ALL
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline.custom_minimum_size.x = 760
	timeline.event_selected.connect(_on_event_selected)
	timeline.track_selected.connect(_on_track_selected)
	timeline.selection_cleared.connect(_clear_timeline_selection)
	timeline.seek_requested.connect(_set_tick)
	timeline_scroll.add_child(timeline)
	return vertical


func _build_timeline_toolbar() -> Control:
	var margin := MarginContainer.new()
	margin.custom_minimum_size.y = 78
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	margin.add_child(stack)
	var heading_row := HBoxContainer.new()
	stack.add_child(heading_row)
	var heading := Label.new()
	heading.text = localization.text("timeline")
	localized_controls["timeline"] = heading
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color("dbe1ea"))
	heading_row.add_child(heading)
	timeline_selection_label = Label.new()
	timeline_selection_label.text = localization.text("selection_none")
	timeline_selection_label.add_theme_color_override("font_color", Color("62d7a3"))
	heading_row.add_child(timeline_selection_label)
	heading_row.add_spacer(false)
	var hint := Label.new()
	hint.text = localization.text("timeline_authoring_hint")
	hint.add_theme_color_override("font_color", Color("939daf"))
	localized_controls["timeline_authoring_hint"] = hint
	heading_row.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	stack.add_child(row)
	var label := Label.new()
	label.text = localization.text("new_event_type")
	label.add_theme_color_override("font_color", Color("8d96a7"))
	localized_controls["new_event_type"] = label
	row.add_child(label)
	event_type_picker = OptionButton.new()
	event_type_picker.custom_minimum_size.x = 150
	_populate_event_type_picker()
	row.add_child(event_type_picker)
	var add_event_button := _localized_button("add_event", _add_event_at_playhead, "tip_add_event")
	add_event_button.theme_type_variation = "PrimaryButton"
	row.add_child(add_event_button)
	row.add_child(_localized_button("add_track", _add_track, "tip_add_track"))
	row.add_spacer(false)
	delete_event_button = _localized_button("delete_event", _delete_selected_event, "tip_delete_event")
	delete_event_button.theme_type_variation = "DangerButton"
	delete_event_button.disabled = true
	row.add_child(delete_event_button)
	delete_track_button = _localized_button("delete_track", _delete_selected_track, "tip_delete_track")
	delete_track_button.theme_type_variation = "DangerButton"
	delete_track_button.disabled = true
	row.add_child(delete_track_button)
	return margin


func _build_inspector() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 300
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	inspector = ActionInspectorPanel.new()
	inspector.localization = localization
	inspector.event_changed.connect(_on_event_changed)
	inspector.validation_failed.connect(func(message: String): _set_status(message, true))
	margin.add_child(inspector)
	return panel


func _build_status_bar() -> Control:
	var bar := MarginContainer.new()
	bar.custom_minimum_size.y = 32
	bar.add_theme_constant_override("margin_left", 10)
	bar.add_theme_constant_override("margin_right", 10)
	bar.add_theme_constant_override("margin_top", 5)
	bar.add_theme_constant_override("margin_bottom", 5)
	var row := HBoxContainer.new()
	bar.add_child(row)
	status_label = Label.new()
	status_label.text = localization.text("ready")
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_color_override("font_color", Color("aab2c0"))
	row.add_child(status_label)
	time_label = Label.new()
	time_label.text = "000 ticks · 0.000 s"
	time_label.add_theme_color_override("font_color", Color("62d7a3"))
	row.add_child(time_label)
	return bar


func _build_dialogs() -> void:
	file_dialog = _file_dialog(FileDialog.FILE_MODE_OPEN_FILE, ["*.action.json ; Action Director action", "*.adproject ; Action Director project"])
	file_dialog.file_selected.connect(_open_file)
	asset_dialog = _file_dialog(FileDialog.FILE_MODE_OPEN_FILE, ["*.png,*.webp,*.wav,*.ogg,*.glb,*.gltf,*.fbx ; Supported assets and Mixamo FBX"])
	asset_dialog.file_selected.connect(_import_asset)
	export_dialog = _file_dialog(FileDialog.FILE_MODE_SAVE_FILE, ["*.action.json ; Action Director action"])
	export_dialog.file_selected.connect(_export_action)
	project_dialog = _file_dialog(FileDialog.FILE_MODE_SAVE_FILE, ["*.adproject ; Action Director project"])
	project_dialog.file_selected.connect(_write_project)
	tutorial_center = ActionTutorialCenter.new()
	tutorial_center.visible = false
	tutorial_center.configure(localization, tutorial_completed, first_run_pending)
	tutorial_center.tutorial_action_requested.connect(_on_tutorial_action)
	tutorial_center.progress_changed.connect(_on_tutorial_progress_changed)
	tutorial_center.manual_requested.connect(_show_manual)
	add_child(tutorial_center)
	manual_window = ActionManualWindow.new()
	manual_window.visible = false
	manual_window.configure(localization)
	add_child(manual_window)


func _file_dialog(mode: FileDialog.FileMode, filters: PackedStringArray) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = filters
	dialog.use_native_dialog = true
	add_child(dialog)
	return dialog


func _open_action(path: String) -> void:
	var loaded := ActionSpecCodec.load_json(path)
	if not loaded.ok:
		_set_status(localization.text("open_failed", [String(loaded.get("error", ""))]), true)
		return
	spec = loaded.spec
	action_path = path
	project_data = ActionProjectStore.create_from_action(path, spec.data)
	current_take_name = spec.get_default_take_name()
	var take_names := spec.get_take_names()
	compare_take_name = take_names[1] if take_names.size() > 1 else current_take_name
	_set_tick(0)
	_rebuild_workspace()
	var warning_count: int = loaded.validation.warnings.size()
	var warning_text := localization.text("compatibility_warnings", [warning_count]) if warning_count else ""
	_set_status(localization.text("action_opened", [spec.data.get("name", spec.action_id), warning_text]))


func _open_file(path: String) -> void:
	if path.get_extension().to_lower() == "adproject":
		_open_project(path)
	else:
		_open_action(path)


func _open_project(path: String) -> void:
	var loaded := ActionProjectStore.load_project(path)
	if not loaded.ok:
		_set_status(_localized_error(loaded), true)
		return
	project_data = loaded.project
	project_path = path
	action_path = String(project_data.get("action_source", ""))
	spec = ActionSpecCodec.from_dictionary(project_data.action_data, action_path)
	current_take_name = spec.get_default_take_name()
	var names := spec.get_take_names()
	compare_take_name = names[1] if names.size() > 1 else current_take_name
	_set_tick(0)
	_rebuild_workspace()
	var source_note := "" if action_path == "" or FileAccess.file_exists(action_path) else localization.text("project_source_missing")
	_set_status(localization.text("project_opened", [project_data.get("name", path.get_file()), source_note]))


func _rebuild_workspace() -> void:
	selected_track_id = ""
	selected_event_id = ""
	_update_workspace_context()
	_rebuild_tree()
	take_tabs.clear_tabs()
	for name in spec.get_take_names():
		take_tabs.add_tab(name)
	var active_index := spec.get_take_names().find(current_take_name)
	if active_index >= 0:
		take_tabs.current_tab = active_index
	_populate_compare_take_picker()
	_rebuild_stages()
	timeline.set_take(spec, current_take_name)
	timeline.clear_selection()
	inspector.set_spec(spec, current_take_name)
	inspector.clear_selection()
	_update_timeline_selection()
	_update_comparison_summary()


func _rebuild_tree() -> void:
	project_tree.clear()
	var root := project_tree.create_item()
	var actions := project_tree.create_item(root)
	actions.set_text(0, localization.text("actions"))
	var action_item := project_tree.create_item(actions)
	action_item.set_text(0, String(spec.data.get("name", spec.action_id)))
	action_item.set_metadata(0, {"kind": "action"})
	var takes := project_tree.create_item(action_item)
	takes.set_text(0, localization.text("takes_count", [spec.get_take_names().size()]))
	for take_name in spec.get_take_names():
		var item := project_tree.create_item(takes)
		item.set_text(0, take_name)
		item.set_metadata(0, {"kind": "take", "name": take_name})
	var actors := project_tree.create_item(root)
	actors.set_text(0, localization.text("actors"))
	for actor: Variant in spec.data.get("actors", []):
		if actor is Dictionary:
			var item := project_tree.create_item(actors)
			item.set_text(0, String(actor.get("name", "Actor")))
	var assets := project_tree.create_item(root)
	assets.set_text(0, localization.text("assets_count", [spec.data.get("assets", []).size()]))
	for asset: Variant in spec.data.get("assets", []):
		if asset is Dictionary:
			var asset_item := project_tree.create_item(assets)
			asset_item.set_text(0, String(asset.get("name", "Asset")))
			var clips: Array = asset.get("animation_clips", [])
			if not clips.is_empty():
				asset_item.set_tooltip_text(0, localization.text("animation_clips", [", ".join(PackedStringArray(clips))]))
	actions.collapsed = false
	takes.collapsed = false
	actors.collapsed = false
	assets.collapsed = false


func _rebuild_stages() -> void:
	_clear_holder(primary_stage_holder)
	_clear_holder(compare_stage_holder)
	if spec.dimension == "3d":
		primary_stage = PreviewStage3D.new()
		compare_stage = PreviewStage3D.new()
		(primary_stage as PreviewStage3D).set_localization(localization)
		(compare_stage as PreviewStage3D).set_localization(localization)
	else:
		primary_stage = PreviewStage2D.new()
		compare_stage = PreviewStage2D.new()
		(primary_stage as PreviewStage2D).set_localization(localization)
		(compare_stage as PreviewStage2D).set_localization(localization)
		(primary_stage as PreviewStage2D).outcome_requested.connect(_on_preview_outcome.bind("primary"))
		(compare_stage as PreviewStage2D).outcome_requested.connect(_on_preview_outcome.bind("compare"))
	primary_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	compare_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compare_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	primary_stage_holder.add_child(primary_stage)
	compare_stage_holder.add_child(compare_stage)
	primary_stage.set_comparison_style(false)
	compare_stage.set_comparison_style(true)
	primary_stage.set_take(spec, current_take_name)
	compare_stage.set_take(spec, compare_take_name)
	var asset_root := _project_asset_root()
	primary_stage.bind_project_assets(asset_root)
	compare_stage.bind_project_assets(asset_root)
	compare_stage_holder.visible = compare_enabled and compare_take_name != current_take_name
	_reset_preview_runtimes(current_tick)


func _clear_holder(holder: Node) -> void:
	for child in holder.get_children():
		if child.is_inside_tree():
			child.queue_free()
		else:
			child.free()


func _set_tick(tick: int) -> void:
	if spec == null:
		return
	current_tick = clampi(tick, 0, _max_preview_duration())
	_reset_preview_runtimes(current_tick)
	_sync_stages_from_runtime()
	if timeline != null:
		timeline.set_tick(current_tick)
	if time_label != null:
		time_label.text = "%03d ticks · %.3f s" % [current_tick, current_tick / 60.0]


func _toggle_playback() -> void:
	if spec == null:
		return
	if current_tick >= _max_preview_duration():
		_set_tick(0)
	elif primary_runtime == null or not primary_runtime.is_active:
		_reset_preview_runtimes(current_tick)
	is_playing = not is_playing
	_preview_accumulator = 0.0
	play_button.text = localization.text("pause") if is_playing else localization.text("play")


func _toggle_compare() -> void:
	compare_enabled = not compare_enabled
	compare_button.text = localization.text("compare_on") if compare_enabled else localization.text("compare_off")
	compare_button.button_pressed = compare_enabled
	compare_stage_holder.visible = compare_enabled and compare_take_name != current_take_name
	_update_comparison_summary()


func _on_take_tab_changed(index: int) -> void:
	if spec == null:
		return
	current_take_name = spec.get_take_names()[index]
	_populate_compare_take_picker()
	_set_tick(0)
	selected_track_id = ""
	selected_event_id = ""
	_rebuild_stages()
	timeline.set_take(spec, current_take_name)
	timeline.clear_selection()
	inspector.set_spec(spec, current_take_name)
	inspector.clear_selection()
	_update_workspace_context()
	_update_timeline_selection()
	_update_comparison_summary()


func _on_compare_take_selected(index: int) -> void:
	if spec == null or compare_take_picker == null or index < 0 or index >= compare_take_picker.item_count:
		return
	var selected_take := String(compare_take_picker.get_item_metadata(index))
	if selected_take == "" or selected_take == current_take_name or selected_take not in spec.get_take_names():
		return
	compare_take_name = selected_take
	_rebuild_stages()
	_update_comparison_summary()
	_set_status(localization.text("comparison_changed", [current_take_name, compare_take_name]))


func _update_comparison_summary() -> void:
	if spec == null:
		return
	var first_difference := ActionTakeUtils.first_difference_tick(spec.get_take(current_take_name), spec.get_take(compare_take_name))
	var delta := spec.get_duration_ticks(compare_take_name) - spec.get_duration_ticks(current_take_name)
	var difference_text := localization.text("tick_value", [first_difference]) if first_difference >= 0 else localization.text("none")
	comparison_label.text = localization.text("first_difference", [current_take_name, compare_take_name, difference_text, delta]) if compare_enabled and current_take_name != compare_take_name else localization.text("no_comparison")
	if difference_button != null:
		difference_button.disabled = not compare_enabled or current_take_name == compare_take_name or first_difference < 0


func _jump_to_first_difference() -> void:
	if spec == null or not compare_enabled or current_take_name == compare_take_name:
		return
	var tick := ActionTakeUtils.first_difference_tick(spec.get_take(current_take_name), spec.get_take(compare_take_name))
	if tick >= 0:
		_set_tick(tick)
		_set_status(localization.text("jumped_to_difference", [tick]))


func _duplicate_current_take() -> void:
	if spec == null:
		return
	var source := spec.get_take(current_take_name)
	if source.is_empty():
		return
	var duplicate := ActionTakeUtils.duplicate_take(source, spec.get_take_names())
	var candidate := String(duplicate.name)
	var before := spec.data.duplicate(true)
	var after := spec.data.duplicate(true)
	after.takes.append(duplicate)
	var source_name := String(source.get("name", ""))
	var previous_compare := compare_take_name
	undo_redo.create_action(localization.text("undo_duplicate_take"))
	undo_redo.add_do_method(_apply_take_snapshot.bind(after, candidate, source_name, localization.text("take_duplicated", [source_name, candidate])))
	undo_redo.add_undo_method(_apply_take_snapshot.bind(before, source_name, previous_compare, localization.text("take_duplication_undone", [candidate])))
	undo_redo.commit_action()


func _apply_take_snapshot(snapshot: Dictionary, active_take: String, comparison_take: String, message: String) -> void:
	spec.data = snapshot.duplicate(true)
	current_take_name = active_take if active_take in spec.get_take_names() else spec.get_default_take_name()
	compare_take_name = comparison_take if comparison_take in spec.get_take_names() else current_take_name
	current_tick = 0
	_rebuild_workspace()
	_set_tick(0)
	_set_status(message)


func _find_first_difference(first: String, second: String) -> int:
	if first == second:
		return -1
	var first_take := spec.get_take(first)
	var second_take := spec.get_take(second)
	var first_events := _event_signatures(first_take)
	var second_events := _event_signatures(second_take)
	for tick in range(0, maxi(int(first_take.get("duration_ticks", 0)), int(second_take.get("duration_ticks", 0))) + 1):
		if first_events.get(tick, []) != second_events.get(tick, []):
			return tick
	return -1


func _event_signatures(take: Dictionary) -> Dictionary:
	var result := {}
	for track: Variant in take.get("tracks", []):
		if track is Dictionary:
			for event: Variant in track.get("events", []):
				if event is Dictionary:
					var tick := int(event.get("start_tick", 0))
					if not result.has(tick):
						result[tick] = []
					result[tick].append([event.get("type"), event.get("end_tick"), event.get("payload")])
	return result


func _on_event_selected(event: Dictionary, track_id: String) -> void:
	selected_track_id = track_id
	selected_event_id = String(event.get("id", ""))
	inspector.inspect_event(event)
	_update_timeline_selection()
	_set_tick(int(event.get("start_tick", 0)))


func _on_track_selected(track: Dictionary) -> void:
	selected_track_id = String(track.get("id", ""))
	selected_event_id = ""
	inspector.clear_selection()
	_update_timeline_selection()
	_set_status(localization.text("track_selected", [track.get("name", "Track")]))


func _clear_timeline_selection() -> void:
	selected_track_id = ""
	selected_event_id = ""
	inspector.clear_selection()
	_update_timeline_selection()


func _add_track() -> void:
	if spec == null:
		return
	var event_type := _selected_event_type()
	var result := ActionAuthoringUtils.add_track(spec.data, current_take_name, event_type)
	if not result.ok:
		_set_status(String(result.error), true)
		return
	_commit_spec_change(
		localization.text("undo_add_track"),
		result.data,
		String(result.track_id),
		"",
		localization.text("track_added", [ActionAuthoringUtils.TRACK_NAMES.get(event_type, event_type.capitalize())])
	)


func _add_event_at_playhead() -> void:
	if spec == null:
		return
	var event_type := _selected_event_type()
	var result := ActionAuthoringUtils.add_event(spec.data, current_take_name, selected_track_id, event_type, current_tick, spec.dimension)
	if not result.ok:
		_set_status(String(result.error), true)
		return
	_commit_spec_change(
		localization.text("undo_add_event"),
		result.data,
		String(result.track_id),
		String(result.event_id),
		localization.text("event_added", [localization.text("event_type_%s" % event_type), current_tick])
	)


func _delete_selected_event() -> void:
	if spec == null or selected_event_id == "":
		_set_status(localization.text("select_event_to_delete"), true)
		return
	var removed_id := selected_event_id
	var result := ActionAuthoringUtils.remove_event(spec.data, current_take_name, removed_id)
	if not result.ok:
		_set_status(String(result.error), true)
		return
	_commit_spec_change(
		localization.text("undo_delete_event"),
		result.data,
		String(result.track_id),
		"",
		localization.text("event_deleted", [removed_id])
	)


func _delete_selected_track() -> void:
	if spec == null or selected_track_id == "":
		_set_status(localization.text("select_track_to_delete"), true)
		return
	var track := _find_track(selected_track_id)
	var track_name := String(track.get("name", selected_track_id))
	var result := ActionAuthoringUtils.remove_track(spec.data, current_take_name, selected_track_id)
	if not result.ok:
		_set_status(String(result.error), true)
		return
	_commit_spec_change(
		localization.text("undo_delete_track"),
		result.data,
		"",
		"",
		localization.text("track_deleted", [track_name, int(result.removed_events)])
	)


func _commit_spec_change(action_name: String, after: Dictionary, track_id: String, event_id: String, message: String) -> void:
	var before := spec.data.duplicate(true)
	undo_redo.create_action(action_name)
	undo_redo.add_do_method(_apply_spec_snapshot.bind(after.duplicate(true), track_id, event_id, message))
	undo_redo.add_undo_method(_apply_spec_snapshot.bind(before, "", "", localization.text("authoring_undone")))
	undo_redo.commit_action()


func _apply_spec_snapshot(snapshot: Dictionary, track_id: String, event_id: String, message: String) -> void:
	spec.data = snapshot.duplicate(true)
	selected_track_id = track_id
	selected_event_id = event_id
	timeline.set_take(spec, current_take_name)
	timeline.set_selection(track_id, event_id)
	inspector.set_spec(spec, current_take_name)
	if event_id != "":
		var event := _find_event(event_id)
		if not event.is_empty():
			inspector.inspect_event(event)
	else:
		inspector.clear_selection()
	_rebuild_stages()
	_update_timeline_selection()
	_update_comparison_summary()
	_set_status(message)


func _selected_event_type() -> String:
	if event_type_picker == null or event_type_picker.item_count == 0:
		return "game_event"
	return String(event_type_picker.get_selected_metadata())


func _find_track(track_id: String) -> Dictionary:
	for take: Variant in spec.data.get("takes", []):
		if not take is Dictionary or String(take.get("name", "")) != current_take_name:
			continue
		for track: Variant in take.get("tracks", []):
			if track is Dictionary and String(track.get("id", "")) == track_id:
				return track.duplicate(true)
	return {}


func _on_event_changed(changed: Dictionary) -> void:
	var original := _find_event(String(changed.get("id", "")))
	if original.is_empty():
		return
	undo_redo.create_action("Edit %s" % changed.get("id", "event"))
	undo_redo.add_do_method(_replace_event.bind(changed.duplicate(true)))
	undo_redo.add_undo_method(_replace_event.bind(original.duplicate(true)))
	undo_redo.commit_action()


func _find_event(event_id: String) -> Dictionary:
	for take: Variant in spec.data.get("takes", []):
		if take is Dictionary and String(take.get("name", "")) == current_take_name:
			for track: Variant in take.get("tracks", []):
				if track is Dictionary:
					for event: Variant in track.get("events", []):
						if event is Dictionary and String(event.get("id", "")) == event_id:
							return event.duplicate(true)
	return {}


func _replace_event(replacement: Dictionary) -> void:
	var result := ActionAuthoringUtils.replace_event(spec.data, current_take_name, replacement)
	if not result.ok:
		return
	spec.data = result.data
	selected_track_id = String(result.track_id)
	selected_event_id = String(replacement.get("id", ""))
	timeline.set_take(spec, current_take_name)
	timeline.set_selection(selected_track_id, selected_event_id)
	inspector.inspect_event(replacement)
	_rebuild_stages()
	_update_timeline_selection()
	_update_comparison_summary()
	_set_status(localization.text("event_updated", [replacement.get("id", "event")]))


func _on_tree_selected() -> void:
	var selected := project_tree.get_selected()
	if selected == null:
		return
	var metadata: Variant = selected.get_metadata(0)
	if metadata is Dictionary and metadata.get("kind") == "take":
		var index := spec.get_take_names().find(String(metadata.get("name", "")))
		if index >= 0:
			take_tabs.current_tab = index
			_on_take_tab_changed(index)


func _on_preview_outcome(event_id: String, outcome: String, side: String) -> void:
	var runtime := primary_runtime if side == "primary" else compare_runtime
	if runtime != null:
		runtime.report_outcome(event_id, outcome)
	_set_status(localization.text("outcome_reported", [side.capitalize(), outcome.to_upper(), event_id]))


func _reset_preview_runtimes(target_tick := 0) -> void:
	if spec == null:
		return
	for runtime in [primary_runtime, compare_runtime]:
		if runtime != null and is_instance_valid(runtime):
			if runtime.is_inside_tree():
				runtime.queue_free()
			else:
				runtime.free()
	primary_runtime = ActionDirectorPlayer.new()
	compare_runtime = ActionDirectorPlayer.new()
	add_child(primary_runtime)
	add_child(compare_runtime)
	primary_runtime.branch_taken.connect(_on_branch_taken.bind("primary"))
	compare_runtime.branch_taken.connect(_on_branch_taken.bind("compare"))
	primary_runtime.event_fired.connect(_on_runtime_event.bind("primary"))
	compare_runtime.event_fired.connect(_on_runtime_event.bind("compare"))
	primary_runtime.play(spec, current_take_name, {"grounded": true})
	compare_runtime.play(spec, compare_take_name, {"grounded": true})
	while primary_runtime.is_active and primary_runtime.current_tick < target_tick:
		primary_runtime.advance_one_tick()
	while compare_runtime.is_active and compare_runtime.current_tick < target_tick:
		compare_runtime.advance_one_tick()
	primary_runtime.pause()
	compare_runtime.pause()


func _sync_stages_from_runtime() -> void:
	if primary_runtime != null and primary_stage != null:
		primary_stage.set_tick(maxi(0, primary_runtime.current_tick))
		current_tick = maxi(0, primary_runtime.current_tick)
	if compare_runtime != null and compare_stage != null:
		compare_stage.set_tick(maxi(0, compare_runtime.current_tick))
	if timeline != null:
		timeline.set_tick(current_tick)
	if time_label != null:
		time_label.text = "%03d ticks · %.3f s" % [current_tick, current_tick / 60.0]


func _on_branch_taken(branch_id: String, target_marker: String, side: String) -> void:
	var stage := primary_stage if side == "primary" else compare_stage
	if stage != null:
		stage.set_branch_notice("%s → %s" % [branch_id, target_marker])
	_set_status(localization.text("branch_taken", [side.capitalize(), branch_id, target_marker]))


func _on_runtime_event(_event_id: String, event_type: String, payload: Dictionary, _side: String) -> void:
	if event_type != "audio":
		return
	var asset := _find_asset(String(payload.get("asset_key", "")))
	if asset.is_empty():
		return
	var full_path := _project_asset_root().path_join(String(asset.get("path", "")))
	var stream: AudioStream
	if full_path.get_extension().to_lower() == "ogg":
		stream = AudioStreamOggVorbis.load_from_file(full_path)
	elif full_path.get_extension().to_lower() == "wav":
		stream = AudioStreamWAV.load_from_file(full_path)
	if stream != null:
		var audio := AudioStreamPlayer.new()
		add_child(audio)
		audio.stream = stream
		audio.finished.connect(audio.queue_free)
		audio.play()


func _find_asset(key: String) -> Dictionary:
	for asset: Variant in spec.data.get("assets", []):
		if asset is Dictionary and key in [String(asset.get("id", "")), String(asset.get("name", ""))]:
			return asset
	return {}


func _project_asset_root() -> String:
	if project_path != "":
		return project_path.get_base_dir()
	if action_path.begins_with("res://"):
		return action_path.get_base_dir()
	if action_path != "":
		return action_path.get_base_dir()
	return OS.get_user_data_dir().path_join("ActionDirectorProject")


func _show_open_dialog() -> void:
	file_dialog.popup_centered_ratio(0.72)


func _show_asset_dialog() -> void:
	asset_dialog.popup_centered_ratio(0.72)


func _show_export_dialog() -> void:
	export_dialog.current_file = "%s.action.json" % String(spec.data.get("name", "action")).to_snake_case()
	export_dialog.popup_centered_ratio(0.72)


func _import_asset(path: String) -> void:
	if project_path == "":
		_set_status(localization.text("save_before_import"), true)
		_save_project()
		return
	var directory := project_path.get_base_dir()
	var result := ActionProjectStore.import_asset(path, directory)
	if not result.ok:
		_set_status(_localized_error(result), true)
		return
	project_data.assets.append(result.asset)
	spec.data.assets.append(result.asset)
	_rebuild_tree()
	var suffix := ""
	if String(result.asset.get("source_extension", "")) == "fbx":
		var clips: Array = result.asset.get("animation_clips", [])
		if clips.is_empty():
			suffix = localization.text("mixamo_no_animation")
		else:
			suffix = localization.text("mixamo_summary", [int(result.asset.get("skeleton_count", 0)), clips.size(), ", ".join(PackedStringArray(clips))])
		_rebuild_stages()
	_set_status(localization.text("imported_asset", [result.asset.name, suffix]), not result.get("warnings", []).is_empty())


func _save_project() -> void:
	if spec == null:
		return
	if project_path == "":
		project_dialog.current_file = "%s.adproject" % String(project_data.get("name", "action-project")).to_snake_case()
		project_dialog.popup_centered_ratio(0.72)
	else:
		_write_project(project_path)


func _write_project(path: String) -> void:
	project_path = path
	project_data.action_source = action_path
	project_data.action_data = spec.data.duplicate(true)
	project_data.assets = spec.data.get("assets", []).duplicate(true)
	var result := ActionProjectStore.save_project(project_data, path)
	var save_message := localization.text("saved_project", [localization.text("saved_backup") if result.get("backup", "") != "" else ""]) if result.ok else _localized_error(result)
	_set_status(save_message, not result.ok)


func _export_action(path: String) -> void:
	var result := ActionSpecCodec.save_json(spec, path)
	if result.ok:
		action_path = path
		_set_status(localization.text("action_exported", [path]))
	else:
		var details := "; ".join(PackedStringArray(result.get("validation", {}).get("errors", [])))
		_set_status("%s %s" % [result.error, details], true)


func _autosave() -> void:
	_last_autosave_msec = Time.get_ticks_msec()
	if spec == null:
		return
	var file := FileAccess.open(AUTOSAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(spec.data, "\t", false, true) + "\n")


func _recover_autosave() -> void:
	if not FileAccess.file_exists(AUTOSAVE_PATH):
		_set_status(localization.text("no_recovery"), true)
		return
	_open_action(AUTOSAVE_PATH)
	_set_status(localization.text("recovered"))


func _max_preview_duration() -> int:
	if spec == null:
		return 0
	return maxi(spec.get_duration_ticks(current_take_name), spec.get_duration_ticks(compare_take_name) if compare_enabled else 0)


func _update_workspace_context() -> void:
	if spec == null:
		if workspace_context_label != null:
			workspace_context_label.text = localization.text("workspace_loading")
		return
	var action_name := String(spec.data.get("name", spec.action_id))
	var take_count := spec.get_take_names().size()
	var dimension := spec.dimension.to_upper()
	if workspace_context_label != null:
		workspace_context_label.text = localization.text("workspace_context", [action_name, current_take_name, take_count])
	if dimension_label != null:
		dimension_label.text = dimension
		dimension_label.tooltip_text = localization.text("dimension_tip", [dimension])


func _update_timeline_selection() -> void:
	if timeline_selection_label != null:
		if selected_event_id != "":
			var event := _find_event(selected_event_id) if spec != null else {}
			var event_type := String(event.get("type", "event"))
			var event_name := localization.text("event_type_%s" % event_type) if event_type in ActionAuthoringUtils.EVENT_TYPES else event_type
			timeline_selection_label.text = localization.text("selection_event", [event_name, int(event.get("start_tick", 0))])
		elif selected_track_id != "":
			var track := _find_track(selected_track_id) if spec != null else {}
			timeline_selection_label.text = localization.text("selection_track", [String(track.get("name", selected_track_id))])
		else:
			timeline_selection_label.text = localization.text("selection_none")
	if delete_event_button != null:
		delete_event_button.disabled = selected_event_id == ""
	if delete_track_button != null:
		delete_track_button.disabled = selected_track_id == ""


func _set_status(message: String, is_error := false) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color("ff7b85") if is_error else Color("aab2c0"))


func _localized_error(result: Dictionary) -> String:
	var key := String(result.get("error_key", ""))
	return localization.text(key, result.get("error_args", [])) if key != "" else String(result.get("error", ""))


func _button(text: String, callback: Callable, tooltip := "") -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	return button


func _localized_button(key: String, callback: Callable, tooltip_key := "") -> Button:
	var button := _button(localization.text(key), callback, localization.text(tooltip_key) if tooltip_key != "" else "")
	localized_controls[key] = button
	if tooltip_key != "":
		localized_tooltips[tooltip_key] = button
	return button


func _populate_event_type_picker() -> void:
	if event_type_picker == null:
		return
	var current := _selected_event_type() if event_type_picker.item_count > 0 else "animation"
	event_type_picker.clear()
	for event_type: String in ActionAuthoringUtils.EVENT_TYPES:
		event_type_picker.add_item(localization.text("event_type_%s" % event_type))
		event_type_picker.set_item_metadata(event_type_picker.item_count - 1, event_type)
		if event_type == current:
			event_type_picker.select(event_type_picker.item_count - 1)


func _populate_compare_take_picker() -> void:
	if compare_take_picker == null:
		return
	compare_take_picker.clear()
	if spec == null:
		compare_take_picker.disabled = true
		return
	var names := spec.get_take_names()
	if compare_take_name not in names or compare_take_name == current_take_name:
		compare_take_name = current_take_name
		for name: String in names:
			if name != current_take_name:
				compare_take_name = name
				break
	for name: String in names:
		if name == current_take_name:
			continue
		compare_take_picker.add_item(name)
		compare_take_picker.set_item_metadata(compare_take_picker.item_count - 1, name)
		if name == compare_take_name:
			compare_take_picker.select(compare_take_picker.item_count - 1)
	if compare_take_picker.item_count == 0:
		compare_take_picker.add_item(localization.text("no_compare_take"))
		compare_take_picker.set_item_metadata(0, "")
		compare_take_picker.disabled = true
	else:
		compare_take_picker.disabled = false


func _on_language_selected(index: int) -> void:
	var locale := String(language_picker.get_item_metadata(index))
	localization.set_locale(locale)
	_save_locale(locale)
	_apply_locale()
	_set_status(localization.text("language_changed", [ActionLocalization.LOCALE_NAMES[locale]]))


func _apply_locale() -> void:
	for key: String in localized_controls:
		var control: Control = localized_controls[key]
		if not is_instance_valid(control):
			continue
		if control is Button:
			(control as Button).text = localization.text(key)
		elif control is Label:
			(control as Label).text = localization.text(key)
	for key: String in localized_tooltips:
		var control: Control = localized_tooltips[key]
		if is_instance_valid(control):
			control.tooltip_text = localization.text(key)
	if compare_button != null:
		compare_button.text = localization.text("compare_on") if compare_enabled else localization.text("compare_off")
	if play_button != null:
		play_button.text = localization.text("pause") if is_playing else localization.text("play")
	if language_picker != null:
		language_picker.tooltip_text = localization.text("language")
	_populate_event_type_picker()
	_populate_compare_take_picker()
	if inspector != null:
		inspector.set_localization(localization)
	if timeline != null:
		timeline.set_localization(localization)
	if primary_stage is PreviewStage2D:
		(primary_stage as PreviewStage2D).set_localization(localization)
	elif primary_stage is PreviewStage3D:
		(primary_stage as PreviewStage3D).set_localization(localization)
	if compare_stage is PreviewStage2D:
		(compare_stage as PreviewStage2D).set_localization(localization)
	elif compare_stage is PreviewStage3D:
		(compare_stage as PreviewStage3D).set_localization(localization)
	if spec != null:
		_rebuild_tree()
		_update_workspace_context()
		_update_timeline_selection()
		_update_comparison_summary()
	if tutorial_center != null:
		tutorial_center.configure(localization, tutorial_completed, false)
	if manual_window != null:
		manual_window.configure(localization)


func _load_settings() -> Dictionary:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				return parsed
	return {}


func _save_locale(locale: String) -> void:
	var settings := _load_settings()
	settings["locale"] = locale
	_save_settings(settings)


func _save_settings(settings: Dictionary) -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings, "\t") + "\n")


func _show_first_run_tutorial() -> void:
	var settings := _load_settings()
	settings["tutorial_seen"] = true
	settings["tutorial_completed"] = tutorial_completed
	_save_settings(settings)
	tutorial_center.open_center("quick_start", true)


func _show_tutorial_center() -> void:
	tutorial_center.open_center("quick_start", false)


func _show_manual() -> void:
	tutorial_center.hide()
	manual_window.open_manual()


func _on_tutorial_action(action: String) -> void:
	if action == "open_3d":
		_open_action(SAMPLE_3D)
	else:
		_open_action(SAMPLE_2D)


func _on_tutorial_progress_changed(value: Array[String]) -> void:
	tutorial_completed.assign(value)
	var settings := _load_settings()
	settings["tutorial_seen"] = true
	settings["tutorial_completed"] = tutorial_completed
	_save_settings(settings)


func _v_separator() -> VSeparator:
	var separator := VSeparator.new()
	separator.custom_minimum_size.x = 8
	return separator
