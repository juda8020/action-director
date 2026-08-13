class_name ActionManualWindow
extends Window

const MANUAL_PATHS := {
	"en": "res://docs/USER_GUIDE.en.md",
	"zh_TW": "res://docs/USER_GUIDE.zh_TW.md",
	"ja": "res://docs/USER_GUIDE.ja.md",
	"ko": "res://docs/USER_GUIDE.ko.md",
}

var localization: ActionLocalization
var manual_text: RichTextLabel
var search_input: LineEdit
var search_status: Label
var close_button: Button
var next_button: Button


func _ready() -> void:
	hide()
	title = "Action Director User Guide"
	size = Vector2i(1120, 780)
	min_size = Vector2i(820, 580)
	transient = true
	exclusive = false
	close_requested.connect(hide)
	_build_interface()
	refresh_locale()


func configure(value: ActionLocalization) -> void:
	localization = value
	if is_node_ready():
		refresh_locale()


func open_manual() -> void:
	refresh_locale()
	popup_centered()
	manual_text.grab_focus()


func refresh_locale() -> void:
	if localization == null or manual_text == null:
		return
	title = localization.text("manual_title")
	search_input.placeholder_text = localization.text("manual_search")
	next_button.text = localization.text("manual_next")
	close_button.text = localization.text("tutorial_close")
	search_status.text = ""
	var locale := ActionLocalization.normalize_locale(localization.locale)
	var path: String = MANUAL_PATHS.get(locale, MANUAL_PATHS["en"])
	var source := _read_manual(path)
	if source == "" and path != MANUAL_PATHS["en"]:
		source = _read_manual(MANUAL_PATHS["en"])
	manual_text.text = _markdown_to_bbcode(source)
	manual_text.scroll_to_line(0)


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F and (event.ctrl_pressed or event.meta_pressed):
		search_input.grab_focus()
		search_input.select_all()
		get_viewport().set_input_as_handled()


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("11151d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 8)
	root.add_child(search_row)
	var brand := Label.new()
	brand.text = "ACTION DIRECTOR"
	brand.add_theme_font_size_override("font_size", 17)
	brand.add_theme_color_override("font_color", Color("f1f4f8"))
	search_row.add_child(brand)
	search_row.add_spacer(false)
	search_input = LineEdit.new()
	search_input.custom_minimum_size.x = 280
	search_input.clear_button_enabled = true
	search_input.text_submitted.connect(func(_query: String): _find_next())
	search_row.add_child(search_input)
	next_button = Button.new()
	next_button.pressed.connect(_find_next)
	search_row.add_child(next_button)
	search_status = Label.new()
	search_status.custom_minimum_size.x = 90
	search_status.add_theme_color_override("font_color", Color("f3b85b"))
	search_row.add_child(search_status)
	manual_text = RichTextLabel.new()
	manual_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	manual_text.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	manual_text.custom_minimum_size.x = 720
	manual_text.bbcode_enabled = true
	manual_text.fit_content = false
	manual_text.selection_enabled = true
	manual_text.context_menu_enabled = true
	manual_text.scroll_active = true
	manual_text.add_theme_font_size_override("normal_font_size", 15)
	manual_text.add_theme_color_override("default_color", Color("d8dde7"))
	root.add_child(manual_text)
	var footer := HBoxContainer.new()
	root.add_child(footer)
	var hint := Label.new()
	hint.text = "Ctrl/Cmd+F  ·  Enter  ·  PgUp/PgDn  ·  Home/End  ·  Esc"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("7f8999"))
	footer.add_child(hint)
	footer.add_spacer(false)
	close_button = Button.new()
	close_button.pressed.connect(hide)
	footer.add_child(close_button)


func _find_next() -> void:
	if search_input.text.strip_edges() == "":
		search_status.text = ""
		return
	var found: bool = manual_text.search(search_input.text, true, false)
	search_status.text = localization.text("manual_found") if found else localization.text("manual_not_found")
	manual_text.grab_focus()


func _read_manual(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _markdown_to_bbcode(source: String) -> String:
	var output: Array[String] = []
	var in_code := false
	for raw_line: String in source.split("\n"):
		var line := raw_line.strip_edges(false, true)
		if line.begins_with("```"):
			output.append("[color=#8d96a7][font_size=13]" if not in_code else "[/font_size][/color]")
			in_code = not in_code
			continue
		var safe := _format_inline(line)
		if in_code:
			output.append("    " + safe)
		elif line.begins_with("# "):
			output.append("[font_size=28][color=#f1f4f8][b]%s[/b][/color][/font_size]" % safe.trim_prefix("# "))
		elif line.begins_with("## "):
			output.append("\n[font_size=21][color=#62d7a3][b]%s[/b][/color][/font_size]" % safe.trim_prefix("## "))
		elif line.begins_with("### "):
			output.append("[font_size=17][color=#f3b85b][b]%s[/b][/color][/font_size]" % safe.trim_prefix("### "))
		elif line.begins_with("- "):
			output.append("[indent]• %s[/indent]" % safe.trim_prefix("- "))
		elif line.is_empty():
			output.append("")
		else:
			output.append(safe)
	return "\n".join(output)


func _escape_bbcode(value: String) -> String:
	return value.replace("[", "\u0001").replace("]", "\u0002").replace("\u0001", "[lb]").replace("\u0002", "[rb]")


func _format_inline(value: String) -> String:
	var safe := _escape_bbcode(value)
	var bold_parts := safe.split("**")
	if bold_parts.size() > 1:
		var rebuilt: Array[String] = []
		for index in bold_parts.size():
			rebuilt.append("[b]%s[/b]" % bold_parts[index] if index % 2 == 1 else bold_parts[index])
		safe = "".join(rebuilt)
	var code_parts := safe.split("`")
	if code_parts.size() > 1:
		var rebuilt: Array[String] = []
		for index in code_parts.size():
			rebuilt.append("[color=#8fdcb9]%s[/color]" % code_parts[index] if index % 2 == 1 else code_parts[index])
		safe = "".join(rebuilt)
	return safe
