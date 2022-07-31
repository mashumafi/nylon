tool
extends EditorPlugin

const Settings := preload("scripts/settings.gd")



func _enter_tree():
	Settings.create_project_settings()
	if Settings.get_add_singleton():
		add_autoload_singleton("Worker", "res://addons/nylon/scripts/worker.gd")
	else:
		remove_autoload_singleton("Worker")


func _exit_tree():
	remove_autoload_singleton("Worker")
	Settings.clear_project_settings()


func get_plugin_icon() -> Texture:
	return preload("icon.png")
