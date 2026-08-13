class_name ActionTutorialCenter
extends Window

signal tutorial_action_requested(action: String)
signal progress_changed(completed: Array[String])
signal manual_requested

var localization: ActionLocalization
var completed: Array[String] = []
var selected_chapter := "quick_start"
var chapter_list: ItemList
var title_label: Label
var summary_label: Label
var progress_label: Label
var steps_box: VBoxContainer
var content_scroll: ScrollContainer
var action_button: Button
var complete_button: Button
var close_button: Button
var manual_button: Button
var first_run := false


func _ready() -> void:
	hide()
	title = "Action Director Tutorial"
	size = Vector2i(1040, 720)
	min_size = Vector2i(820, 580)
	transient = true
	exclusive = false
	close_requested.connect(hide)
	_build_interface()
	refresh_locale()


func configure(value: ActionLocalization, completed_chapters: Array, is_first_run := false) -> void:
	localization = value
	completed.assign(completed_chapters)
	first_run = is_first_run
	if is_node_ready():
		refresh_locale()


func open_center(chapter_id := "quick_start", is_first_run := false) -> void:
	selected_chapter = chapter_id if chapter_id in ActionTutorialCatalog.CHAPTER_IDS else "quick_start"
	first_run = is_first_run
	if is_node_ready():
		refresh_locale()
	popup_centered()
	chapter_list.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var scroll_bar := content_scroll.get_v_scroll_bar()
	match event.keycode:
		KEY_ESCAPE:
			hide()
		KEY_PAGEUP:
			scroll_bar.value -= maxf(scroll_bar.page * 0.85, 120.0)
		KEY_PAGEDOWN:
			scroll_bar.value += maxf(scroll_bar.page * 0.85, 120.0)
		KEY_HOME:
			scroll_bar.value = scroll_bar.min_value
		KEY_END:
			scroll_bar.value = scroll_bar.max_value
		_:
			return
	get_viewport().set_input_as_handled()


func refresh_locale() -> void:
	if localization == null or chapter_list == null:
		return
	title = localization.text("tutorial_title")
	chapter_list.clear()
	var selected_index := 0
	for index in ActionTutorialCatalog.CHAPTER_IDS.size():
		var chapter_id: String = ActionTutorialCatalog.CHAPTER_IDS[index]
		var chapter := ActionTutorialCatalog.get_chapter(localization.locale, chapter_id)
		var marker := "✓ " if chapter_id in completed else ""
		chapter_list.add_item(marker + String(chapter.get("title", chapter_id)))
		chapter_list.set_item_metadata(index, chapter_id)
		if chapter_id == selected_chapter:
			selected_index = index
	chapter_list.select(selected_index)
	close_button.text = localization.text("tutorial_skip") if first_run else localization.text("tutorial_close")
	manual_button.text = localization.text("manual")
	_render_chapter()


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("11151d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var brand := Label.new()
	brand.text = "ACTION DIRECTOR"
	brand.add_theme_font_size_override("font_size", 17)
	brand.add_theme_color_override("font_color", Color("f1f4f8"))
	header.add_child(brand)
	header.add_spacer(false)
	progress_label = Label.new()
	progress_label.add_theme_color_override("font_color", Color("62d7a3"))
	header.add_child(progress_label)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 285
	root.add_child(split)
	chapter_list = ItemList.new()
	chapter_list.custom_minimum_size.x = 270
	chapter_list.item_selected.connect(_on_chapter_selected)
	split.add_child(chapter_list)
	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_scroll.focus_mode = Control.FOCUS_ALL
	split.add_child(content_scroll)
	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.custom_minimum_size.x = 420
	content_margin.add_theme_constant_override("margin_left", 22)
	content_margin.add_theme_constant_override("margin_right", 10)
	content_scroll.add_child(content_margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	content_margin.add_child(content)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 25)
	title_label.add_theme_color_override("font_color", Color("f1f4f8"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(title_label)
	summary_label = Label.new()
	summary_label.add_theme_font_size_override("font_size", 14)
	summary_label.add_theme_color_override("font_color", Color("aab2c0"))
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(summary_label)
	content.add_child(HSeparator.new())
	steps_box = VBoxContainer.new()
	steps_box.add_theme_constant_override("separation", 12)
	content.add_child(steps_box)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	root.add_child(footer)
	close_button = Button.new()
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.pressed.connect(hide)
	footer.add_child(close_button)
	manual_button = Button.new()
	manual_button.focus_mode = Control.FOCUS_ALL
	manual_button.pressed.connect(func(): manual_requested.emit())
	footer.add_child(manual_button)
	var scroll_hint := Label.new()
	scroll_hint.text = "PgUp / PgDn / Home / End"
	scroll_hint.add_theme_font_size_override("font_size", 11)
	scroll_hint.add_theme_color_override("font_color", Color("7f8999"))
	footer.add_child(scroll_hint)
	footer.add_spacer(false)
	action_button = Button.new()
	action_button.focus_mode = Control.FOCUS_ALL
	action_button.pressed.connect(_request_action)
	footer.add_child(action_button)
	complete_button = Button.new()
	complete_button.focus_mode = Control.FOCUS_ALL
	complete_button.pressed.connect(_toggle_complete)
	footer.add_child(complete_button)


func _on_chapter_selected(index: int) -> void:
	selected_chapter = String(chapter_list.get_item_metadata(index))
	_render_chapter()


func _render_chapter() -> void:
	if localization == null or steps_box == null:
		return
	var chapter := ActionTutorialCatalog.get_chapter(localization.locale, selected_chapter)
	title_label.text = String(chapter.get("title", selected_chapter))
	summary_label.text = "%s  ·  %s" % [chapter.get("time", ""), chapter.get("summary", "")]
	for child in steps_box.get_children():
		child.queue_free()
	var steps: Array = chapter.get("steps", [])
	for index in steps.size():
		var step: Array = steps[index]
		steps_box.add_child(_build_step(index + 1, String(step[0]), String(step[1])))
	var action := String(chapter.get("action", "none"))
	action_button.visible = action != "none"
	action_button.set_meta("tutorial_action", action)
	action_button.text = localization.text("tutorial_open_3d") if action == "open_3d" else localization.text("tutorial_open_2d")
	complete_button.text = localization.text("tutorial_mark_undone") if selected_chapter in completed else localization.text("tutorial_mark_done")
	progress_label.text = localization.text("tutorial_progress", [completed.size(), ActionTutorialCatalog.CHAPTER_IDS.size()])


func _build_step(number: int, heading: String, body: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var number_label := Label.new()
	number_label.text = "%02d" % number
	number_label.custom_minimum_size.x = 34
	number_label.add_theme_font_size_override("font_size", 12)
	number_label.add_theme_color_override("font_color", Color("62d7a3"))
	row.add_child(number_label)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.add_theme_font_size_override("font_size", 15)
	heading_label.add_theme_color_override("font_color", Color("e5e9f0"))
	heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(heading_label)
	var body_label := Label.new()
	body_label.text = body
	body_label.add_theme_font_size_override("font_size", 13)
	body_label.add_theme_color_override("font_color", Color("aab2c0"))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(body_label)
	row.add_child(text_column)
	return row


func _request_action() -> void:
	var action := String(action_button.get_meta("tutorial_action", "none"))
	if action != "none":
		tutorial_action_requested.emit(action)
		hide()


func _toggle_complete() -> void:
	if selected_chapter in completed:
		completed.erase(selected_chapter)
	else:
		completed.append(selected_chapter)
	progress_changed.emit(completed.duplicate())
	refresh_locale()
