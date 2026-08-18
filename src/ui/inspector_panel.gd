class_name ActionInspectorPanel
extends VBoxContainer

signal event_changed(event: Dictionary)
signal validation_failed(message: String)

var selected_event: Dictionary = {}
var spec: ActionSpec
var active_take_name := ""
var take_duration := 100000
var title_label: Label
var id_value: Label
var type_picker: OptionButton
var actor_picker: OptionButton
var start_spin: SpinBox
var end_spin: SpinBox
var payload_text: TextEdit
var apply_button: Button
var error_label: Label
var localization: ActionLocalization
var field_labels: Dictionary = {}
var hint_label: Label
var section_label: Label
var empty_label: Label
var fields_container: VBoxContainer


func _ready() -> void:
	if title_label != null:
		return
	localization = ActionLocalization.new("en") if localization == null else localization
	section_label = _label(localization.text("inspector"), 11, Color("aeb7c6"))
	add_child(section_label)
	title_label = _label(localization.text("no_event"), 18)
	add_child(title_label)
	add_child(_separator())
	empty_label = _label(localization.text("inspector_empty"), 13, Color("aab4c4"))
	empty_label.custom_minimum_size.y = 112
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(empty_label)
	fields_container = VBoxContainer.new()
	fields_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fields_container.add_theme_constant_override("separation", 6)
	add_child(fields_container)
	field_labels.event_id = _label(localization.text("event_id"), 11, Color("7f8999"))
	fields_container.add_child(field_labels.event_id)
	id_value = _label("—", 13)
	id_value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	id_value.tooltip_text = "—"
	fields_container.add_child(id_value)
	field_labels.type = _label(localization.text("type"), 11, Color("7f8999"))
	fields_container.add_child(field_labels.type)
	type_picker = OptionButton.new()
	type_picker.item_selected.connect(func(_index: int): _validate_payload())
	fields_container.add_child(type_picker)
	field_labels.actor_id = _label(localization.text("actor_id"), 11, Color("7f8999"))
	fields_container.add_child(field_labels.actor_id)
	actor_picker = OptionButton.new()
	actor_picker.item_selected.connect(func(_index: int): _validate_payload())
	fields_container.add_child(actor_picker)
	var timing_row := HBoxContainer.new()
	timing_row.add_theme_constant_override("separation", 8)
	fields_container.add_child(timing_row)
	var start_column := VBoxContainer.new()
	start_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timing_row.add_child(start_column)
	field_labels.start_tick = _label(localization.text("start_tick"), 11, Color("7f8999"))
	start_column.add_child(field_labels.start_tick)
	start_spin = SpinBox.new()
	start_spin.max_value = 100000
	start_spin.value_changed.connect(func(_value: float): _validate_payload())
	start_column.add_child(start_spin)
	var end_column := VBoxContainer.new()
	end_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timing_row.add_child(end_column)
	field_labels.end_tick = _label(localization.text("end_tick"), 11, Color("7f8999"))
	end_column.add_child(field_labels.end_tick)
	end_spin = SpinBox.new()
	end_spin.max_value = 100000
	end_spin.value_changed.connect(func(_value: float): _validate_payload())
	end_column.add_child(end_spin)
	field_labels.payload_json = _label(localization.text("payload_json"), 11, Color("7f8999"))
	fields_container.add_child(field_labels.payload_json)
	payload_text = TextEdit.new()
	payload_text.custom_minimum_size.y = 190
	payload_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	payload_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	payload_text.text_changed.connect(_validate_payload)
	fields_container.add_child(payload_text)
	error_label = _label("", 11, Color("ff7b85"))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fields_container.add_child(error_label)
	apply_button = Button.new()
	apply_button.text = localization.text("apply_event")
	apply_button.theme_type_variation = "PrimaryButton"
	apply_button.disabled = true
	apply_button.pressed.connect(_apply_changes)
	fields_container.add_child(apply_button)
	hint_label = _label(localization.text("inspector_hint"), 11, Color("8d96a7"))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fields_container.add_child(hint_label)
	_rebuild_type_picker()
	_rebuild_actor_picker()
	_set_editor_visible(false)


func set_localization(value: ActionLocalization) -> void:
	localization = value
	if not is_node_ready():
		return
	if selected_event.is_empty():
		title_label.text = localization.text("no_event")
	section_label.text = localization.text("inspector")
	empty_label.text = localization.text("inspector_empty")
	for key: String in field_labels:
		(field_labels[key] as Label).text = localization.text(key)
	apply_button.text = localization.text("apply_event")
	hint_label.text = localization.text("inspector_hint")
	_rebuild_type_picker()
	_rebuild_actor_picker()
	_validate_payload()


func set_spec(value: ActionSpec, take_name := "") -> void:
	spec = value
	active_take_name = take_name
	if start_spin == null or end_spin == null:
		return
	take_duration = spec.get_duration_ticks(take_name) if spec != null and take_name != "" else 100000
	start_spin.max_value = take_duration
	end_spin.max_value = take_duration
	_rebuild_actor_picker()


func clear_selection() -> void:
	selected_event = {}
	if not is_node_ready():
		return
	title_label.text = localization.text("no_event")
	id_value.text = "—"
	payload_text.text = "{}"
	start_spin.value = 0
	end_spin.value = 0
	_rebuild_type_picker()
	_rebuild_actor_picker()
	_set_editor_visible(false)
	_validate_payload()


func inspect_event(event: Dictionary) -> void:
	selected_event = event.duplicate(true)
	_set_editor_visible(true)
	title_label.text = String(event.get("payload", {}).get("kind", event.get("payload", {}).get("clip", event.get("type", "Event")))).capitalize()
	id_value.text = String(event.get("id", "—"))
	id_value.tooltip_text = id_value.text
	_rebuild_type_picker(String(event.get("type", "")))
	_rebuild_actor_picker(String(event.get("actor_id", "")))
	start_spin.value = int(event.get("start_tick", 0))
	end_spin.value = int(event.get("end_tick", 0))
	payload_text.text = JSON.stringify(event.get("payload", {}), "\t")
	_validate_payload()


func _apply_changes() -> void:
	if selected_event.is_empty():
		return
	var parsed: Variant = JSON.parse_string(payload_text.text)
	if not parsed is Dictionary:
		validation_failed.emit(localization.text("payload_apply_invalid"))
		return
	if int(start_spin.value) < 0 or int(end_spin.value) > take_duration:
		validation_failed.emit(localization.text("timing_out_of_range", [take_duration]))
		return
	var contract_error := _draft_contract_error(parsed)
	if contract_error != "":
		validation_failed.emit(localization.text("event_contract_invalid", [contract_error]))
		return
	selected_event = _edited_event(parsed)
	event_changed.emit(selected_event.duplicate(true))
	error_label.text = ""
	_validate_payload()


func _validate_payload() -> void:
	if payload_text == null or apply_button == null:
		return
	var parsed: Variant = JSON.parse_string(payload_text.text)
	var valid := parsed is Dictionary
	var changed := valid and not selected_event.is_empty() and _has_changes(parsed)
	var contract_error := _draft_contract_error(parsed) if valid and not selected_event.is_empty() else ""
	apply_button.disabled = selected_event.is_empty() or not valid or not changed or contract_error != ""
	if not valid and not selected_event.is_empty():
		error_label.text = localization.text("payload_invalid")
	elif contract_error != "":
		error_label.text = localization.text("event_contract_invalid", [contract_error])
	else:
		error_label.text = ""


func _draft_contract_error(parsed_payload: Dictionary) -> String:
	if spec == null or active_take_name == "":
		return ""
	var replacement := _edited_event(parsed_payload)
	var replaced := ActionAuthoringUtils.replace_event(spec.data, active_take_name, replacement)
	if not replaced.get("ok", false):
		return String(replaced.get("error", "The event could not be updated."))
	var validation := ActionSpecCodec.validate(replaced.data)
	if validation.ok:
		return ""
	return String(validation.errors[0]) if not validation.errors.is_empty() else "The edited ActionSpec is invalid."


func _edited_event(parsed_payload: Dictionary) -> Dictionary:
	var edited := selected_event.duplicate(true)
	edited.start_tick = int(start_spin.value)
	edited.end_tick = clampi(maxi(int(end_spin.value), int(start_spin.value)), 0, take_duration)
	edited.type = String(type_picker.get_selected_metadata())
	edited.actor_id = String(actor_picker.get_selected_metadata())
	edited.payload = parsed_payload.duplicate(true)
	return edited


func _has_changes(parsed_payload: Dictionary) -> bool:
	return (
		int(start_spin.value) != int(selected_event.get("start_tick", 0))
		or clampi(maxi(int(end_spin.value), int(start_spin.value)), 0, take_duration) != int(selected_event.get("end_tick", 0))
		or String(type_picker.get_selected_metadata()) != String(selected_event.get("type", ""))
		or String(actor_picker.get_selected_metadata()) != String(selected_event.get("actor_id", ""))
		or JSON.stringify(parsed_payload, "", true) != JSON.stringify(selected_event.get("payload", {}), "", true)
	)


func _set_editor_visible(has_selection: bool) -> void:
	if empty_label != null:
		empty_label.visible = not has_selection
	if fields_container != null:
		fields_container.visible = has_selection


func _label(text: String, font_size: int, color := Color("d8dde7")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.custom_minimum_size.y = 8
	return separator


func _rebuild_type_picker(selected_type := "") -> void:
	if type_picker == null:
		return
	var current := selected_type if selected_type != "" else String(selected_event.get("type", ""))
	type_picker.clear()
	for event_type: String in ActionAuthoringUtils.EVENT_TYPES:
		type_picker.add_item(localization.text("event_type_%s" % event_type))
		type_picker.set_item_metadata(type_picker.item_count - 1, event_type)
	if current != "" and current not in ActionAuthoringUtils.EVENT_TYPES:
		type_picker.add_item(localization.text("unknown_event_type", [current]))
		type_picker.set_item_metadata(type_picker.item_count - 1, current)
	_select_metadata(type_picker, current if current != "" else "animation")


func _rebuild_actor_picker(selected_actor := "") -> void:
	if actor_picker == null:
		return
	var current := selected_actor if selected_actor != "" else String(selected_event.get("actor_id", ""))
	actor_picker.clear()
	actor_picker.add_item(localization.text("no_actor"))
	actor_picker.set_item_metadata(0, "")
	if spec != null:
		for actor: Variant in spec.data.get("actors", []):
			if not actor is Dictionary:
				continue
			var actor_id := String(actor.get("id", ""))
			var actor_name := String(actor.get("name", actor_id))
			actor_picker.add_item("%s · %s" % [actor_name, actor_id])
			actor_picker.set_item_metadata(actor_picker.item_count - 1, actor_id)
	if current != "" and not _option_has_metadata(actor_picker, current):
		actor_picker.add_item(localization.text("missing_actor", [current]))
		actor_picker.set_item_metadata(actor_picker.item_count - 1, current)
	_select_metadata(actor_picker, current)


func _select_metadata(picker: OptionButton, value: String) -> void:
	for index in picker.item_count:
		if String(picker.get_item_metadata(index)) == value:
			picker.select(index)
			return
	picker.select(0)


func _option_has_metadata(picker: OptionButton, value: String) -> bool:
	for index in picker.item_count:
		if String(picker.get_item_metadata(index)) == value:
			return true
	return false
