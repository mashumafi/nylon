# Cacoon

tool
class_name Cacoon
extends Nylon

# Current Coroutine
var _coroutine : Coroutine

# instance
# Object which will be used
export(NodePath) onready var instance : NodePath setget set_instance, get_instance
func set_instance(new_instance: NodePath) -> void:
    instance = new_instance
    update_configuration_warning()
func get_instance() -> NodePath:
    return instance

# func_name
# Name of the function to call
export(String) var func_name := "" setget set_func_name, get_func_name
func set_func_name(new_func_name) -> void:
    func_name = new_func_name
    update_configuration_warning()
func get_func_name() -> String:
    return func_name

# How long to wait before calling the function
# This delay occurs after the function no longer yields
export(int, 0, 2147483647) var start_delay := 0

# How long to wait after the function yields
export(int, 0, 2147483647) var resume_delay := 0

# How many times to replay the function
# 0 will run the function until cancelled
export(int, 0, 2147483647) var replay := 1

func _ready() -> void:
    run_async(get_node(instance), func_name, replay if replay > 0 else true)

# run_async(instance: Object, funcname: String, replay: int | bool) -> Coroutine
# instance (Object): object to call a function
# funcname (String): name of the function to call
# replay (int | bool): How many times to call the function
#                      Using `true` repeats until cancelled
func run_async(instance, funcname: String, replay = 1) -> Coroutine:
    var job := Silk.new(weakref(instance), funcname) \
        .timed_resume(resume_delay) \
        .timed_callable(start_delay) \
        .build(replay)
    _coroutine = Coroutine.new(Callable.new(job[0], job[1]), job[2])
    return _coroutine

func _run_coroutines() -> void:
    if _coroutine and _coroutine.is_valid():
        _coroutine.resume()

func _get_configuration_warning() -> String:
    if not instance or not has_node(instance):
        return "Set node path"
    var node := get_node(instance)
    if func_name.empty():
        return "Provide a function from " + node.get_class()
    elif not node.has_method(func_name):
        return "{0} is missing function {1}".format([instance, func_name])
    return ""
