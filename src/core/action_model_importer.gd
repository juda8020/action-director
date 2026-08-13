class_name ActionModelImporter
extends RefCounted


static func load_scene(path: String) -> Dictionary:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is PackedScene:
			var imported_scene := (resource as PackedScene).instantiate()
			if imported_scene is Node3D:
				return {"ok": true, "scene": imported_scene, "metadata": inspect_scene(imported_scene)}
			imported_scene.free()
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Model file does not exist: %s" % path}
	var extension := path.get_extension().to_lower()
	var document: GLTFDocument
	var state: GLTFState
	if extension == "fbx":
		document = FBXDocument.new()
		state = FBXState.new()
	elif extension in ["glb", "gltf"]:
		document = GLTFDocument.new()
		state = GLTFState.new()
	else:
		return {"ok": false, "error": "Unsupported 3D model type .%s." % extension}
	var error := document.append_from_file(path, state)
	if error != OK:
		return {"ok": false, "error": "Godot could not parse %s (error %d)." % [path.get_file(), error]}
	var scene := document.generate_scene(state)
	if not scene is Node3D:
		return {"ok": false, "error": "The model did not generate a 3D scene."}
	var metadata := inspect_scene(scene)
	return {"ok": true, "scene": scene, "metadata": metadata}


static func inspect_file(path: String) -> Dictionary:
	var result := load_scene(path)
	if not result.ok:
		return result
	var scene: Node3D = result.scene
	scene.free()
	return {"ok": true, "metadata": result.metadata}


static func inspect_scene(scene: Node) -> Dictionary:
	var clips: Array[String] = []
	var skeleton_count := 0
	var mesh_count := 0
	var animation_player_count := 0
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Skeleton3D:
			skeleton_count += 1
		elif node is MeshInstance3D:
			mesh_count += 1
		elif node is AnimationPlayer:
			animation_player_count += 1
			for clip: StringName in (node as AnimationPlayer).get_animation_list():
				var clean := String(clip)
				if clean != "RESET" and clean not in clips:
					clips.append(clean)
		for child in node.get_children():
			if child is Node:
				stack.append(child)
	clips.sort()
	return {
		"skeleton_count": skeleton_count,
		"mesh_count": mesh_count,
		"animation_player_count": animation_player_count,
		"animation_clips": clips,
		"mixamo_compatible": skeleton_count > 0 and not clips.is_empty(),
	}
