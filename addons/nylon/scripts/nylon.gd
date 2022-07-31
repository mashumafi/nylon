class_name Nylon
extends Node

enum WorkerProcessMode { IDLE, PHYSICS }

const Callable := preload("callable.gd")
const Settings := preload("settings.gd")

export(WorkerProcessMode) var process_mode := WorkerProcessMode.IDLE setget set_process_mode, get_process_mode

# How long (milliseconds) to spend processing jobs before stopping
# Jobs are processed using round-robbin and continues each frame
# Use lower numbers if you see frames dropping, 0 will process 1 job per frame
# Can be configured from Project Settings under Nylon section
export(int) var process_timeout = Settings.get_process_timeout()


func set_process_mode(new_process_mode: int) -> void:
	process_mode = new_process_mode
	set_process(WorkerProcessMode.IDLE == process_mode)
	set_physics_process(WorkerProcessMode.PHYSICS == process_mode)


func get_process_mode() -> int:
	return process_mode


func _ready() -> void:
	set_process_mode(process_mode)


func _process(_delta: float) -> void:
	_run_coroutines()


func _physics_process(_delta: float) -> void:
	_run_coroutines()


func _run_coroutines() -> void:
	pass
