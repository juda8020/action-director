class_name ActionSpecImporter
extends RefCounted


static func import_json_to_tres(json_path: String, tres_path: String) -> Dictionary:
	var loaded := ActionSpecCodec.load_json(json_path)
	if not loaded.ok:
		return loaded
	var save_error := ResourceSaver.save(loaded.spec, tres_path)
	if save_error != OK:
		return {"ok": false, "error": "Could not write ActionSpec cache: %s" % tres_path}
	return {"ok": true, "spec": loaded.spec, "warnings": loaded.validation.warnings}
