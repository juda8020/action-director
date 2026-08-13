extends SceneTree

const APP_SCENE := preload("res://src/app/action_director_app.tscn")
const OUTPUT_PATH := "res://docs/media/action-director-workbench.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var app: Control = APP_SCENE.instantiate()
	root.add_child(app)
	for _frame in range(6):
		await process_frame
	if app.tutorial_center != null:
		app.tutorial_center.hide()
	app.localization.set_locale("en")
	app.language_picker.select(0)
	app._apply_locale()
	app._set_tick(18)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/media"))
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Could not save website screenshot: %s" % error_string(error))
	quit(error)
