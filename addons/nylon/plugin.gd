@tool
extends EditorPlugin


const WORKER := "NylonWorker"


func _enter_tree():
	add_autoload_singleton(WORKER, "res://addons/nylon/worker.gd")
	NylonSettings.create_project_settings()


func _exit_tree():
	remove_autoload_singleton(WORKER)
	NylonSettings.clear_project_settings()
