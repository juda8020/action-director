class_name ActionProjectStore
extends RefCounted

const PROJECT_SCHEMA := "1.0.0"


static func create_from_action(action_path: String, action_data: Dictionary) -> Dictionary:
	return {
		"schema_version": PROJECT_SCHEMA,
		"project_id": "adproject-%s" % Time.get_unix_time_from_system(),
		"name": String(action_data.get("name", "Untitled Action")),
		"dimension": String(action_data.get("dimension", "2d")),
		"action_source": action_path,
		"action_data": action_data.duplicate(true),
		"assets": action_data.get("assets", []).duplicate(true),
		"stage": {"grid": true, "ground": true, "camera": {}},
		"workspace": {
			"left_width": 270,
			"right_width": 300,
			"timeline_height": 300,
			"current_take": String(action_data.get("takes", [{}])[0].get("name", "Default")) if not action_data.get("takes", []).is_empty() else "Default",
			"compare_take": "",
			"compare_enabled": true,
			"preview_tick": 0,
		},
	}


static func load_project(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("project_missing", [path], "Project file does not exist: %s" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("project_cannot_open", [path], "Project file could not be opened: %s" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _failure("project_damaged", [], "Project file is damaged. The original file was not changed.")
	if String(parsed.get("schema_version", "")) == "":
		return _failure("project_no_schema", [], "Project file has no schema version.")
	if not parsed.get("action_data") is Dictionary:
		return _failure("project_no_action", [], "Project has no embedded ActionSpec. Reopen the original action and save this workspace again.")
	var action_validation := ActionSpecCodec.validate(parsed.action_data)
	if not action_validation.ok:
		var failure := _failure("project_action_invalid", [], "Embedded ActionSpec is invalid; the project was not modified.")
		failure["validation"] = action_validation
		return failure
	return {"ok": true, "project": parsed}


static func save_project(project: Dictionary, path: String) -> Dictionary:
	var temp_path := path + ".tmp"
	var backup_path := path + ".backup"
	var temp := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		return _failure("project_temp_failed", [], "Could not create temporary project file.")
	temp.store_string(JSON.stringify(project, "\t", false, true) + "\n")
	temp.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, backup_path)
	var rename_error := DirAccess.rename_absolute(temp_path, path)
	if rename_error != OK:
		return _failure("project_replace_failed", [temp_path], "Could not replace project file safely. Temporary data remains at %s." % temp_path)
	return {"ok": true, "backup": backup_path if FileAccess.file_exists(backup_path) else ""}


static func import_asset(source_path: String, project_directory: String) -> Dictionary:
	var allowed := ["png", "webp", "wav", "ogg", "glb", "gltf", "fbx"]
	var extension := source_path.get_extension().to_lower()
	if extension not in allowed:
		return _failure("asset_unsupported", [extension], "Unsupported asset type .%s." % extension)
	if not FileAccess.file_exists(source_path):
		return _failure("asset_not_found", [source_path], "Asset no longer exists: %s" % source_path)
	var asset_directory := project_directory.path_join("assets")
	DirAccess.make_dir_recursive_absolute(asset_directory)
	var destination_name := _available_asset_filename(asset_directory, source_path.get_file())
	var destination := asset_directory.path_join(destination_name)
	var copy_error := DirAccess.copy_absolute(source_path, destination)
	if copy_error != OK:
		return _failure("asset_copy_failed", [], "Could not copy the asset into the project.")
	var asset := {
		"id": destination_name.get_basename().to_snake_case(),
		"name": source_path.get_file().get_basename(),
		"kind": _asset_kind(extension),
		"path": "assets/%s" % destination_name,
		"source_extension": extension,
	}
	var warnings: Array[String] = []
	if extension in ["fbx", "glb", "gltf"]:
		var inspected := ActionModelImporter.inspect_file(destination)
		if not inspected.ok:
			DirAccess.remove_absolute(destination)
			return {"ok": false, "error_key": "model_parse_failed", "error_args": [source_path.get_file(), String(inspected.error)], "error": String(inspected.error)}
		else:
			var metadata: Dictionary = inspected.metadata
			asset["importer"] = "ufbx" if extension == "fbx" else "gltf"
			asset["skeleton_count"] = metadata.skeleton_count
			asset["mesh_count"] = metadata.mesh_count
			asset["animation_clips"] = metadata.animation_clips
			asset["mixamo_compatible"] = metadata.mixamo_compatible
			if extension == "fbx" and int(metadata.skeleton_count) == 0:
				warnings.append("The FBX has no skeleton. Download the Mixamo character with Skin enabled.")
			if extension == "fbx" and metadata.animation_clips.is_empty():
				warnings.append("The FBX has no animation clip. Download the Mixamo motion as FBX Binary.")
	return {
		"ok": true,
		"asset": asset,
		"warnings": warnings,
	}


static func _available_asset_filename(asset_directory: String, source_filename: String) -> String:
	if not FileAccess.file_exists(asset_directory.path_join(source_filename)):
		return source_filename
	var extension := source_filename.get_extension()
	var basename := source_filename.get_basename()
	var suffix := 2
	while true:
		var candidate := "%s_%d%s" % [basename, suffix, ".%s" % extension if extension != "" else ""]
		if not FileAccess.file_exists(asset_directory.path_join(candidate)):
			return candidate
		suffix += 1
	return source_filename


static func _asset_kind(extension: String) -> String:
	if extension in ["png", "webp"]:
		return "image"
	if extension in ["wav", "ogg"]:
		return "audio"
	return "model"


static func _failure(key: String, arguments: Array, fallback: String) -> Dictionary:
	return {"ok": false, "error_key": key, "error_args": arguments, "error": fallback}
