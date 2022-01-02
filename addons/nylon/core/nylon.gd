class_name Nylon
extends Node

const Callable := preload("callable.gd")

enum WorkerProcessMode {IDLE, PHYSICS}
export(WorkerProcessMode) var process_mode := WorkerProcessMode.IDLE setget set_process_mode, get_process_mode
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
