# Cacoon

tool
class_name Cacoon
extends Nylon

# Current Coroutine
var _coroutine : Coroutine

#
export(NodePath) onready var instance : NodePath setget set_instance, get_instance
func set_instance(new_instance: NodePath) -> void:
    instance = new_instance
    update_configuration_warning()
func get_instance() -> NodePath:
    return instance

#
export(String) var funcname := "" setget set_funcname, get_funcname
func set_funcname(new_funcname) -> void:
    funcname = new_funcname
    update_configuration_warning()
func get_funcname() -> String:
    return funcname

#
export(int) var timed_delay := 0

#
export(int) var resume_delay := 0

#
export(int, 0, 2147483647) var replay := 1

func _ready() -> void:
    run_async(get_node(instance), funcname, replay if replay > 0 else true)

# run_async(callable: Callable, replay: int | bool) -> Coroutine
# instance (Object): object to call a function
# funcname (String): name of the function to call
# replay (int | bool): How many times to call the function
#                      Using `true` repeats until cancelled
func run_async(instance, funcname: String, replay = 1) -> Coroutine:
    var job := Silk.new(instance, funcname) \
        .timed_resume(resume_delay) \
        .timed_callable(timed_delay) \
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
    if funcname.empty():
        return "Provide a function from " + node.get_class()
    elif not node.has_method(funcname):
        return "{0} is missing function {1}".format([instance, funcname])
    return ""
