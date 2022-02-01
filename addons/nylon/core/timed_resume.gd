# TimedResume
# Processes a coroutine until `timeout`

class_name TimedResume
extends Reference

const Callable := preload("callable.gd")

var callable : Callable
var timeout := 0

# TimedResume.new(instance: Object, funcname: String, timeout : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# timeout (int): Time in milliseconds to spend proccesing the coroutine
func _init(instance, funcname: String, timeout := 0):
    self.callable = Callable.new(instance, funcname)
    self.timeout = timeout

# call_func():
# Processes a coroutine until `timeout`
func call_func():
    var time := OS.get_system_time_msecs()
    var state = self.callable.call_func()
    while state is GDScriptFunctionState:
        if OS.get_system_time_msecs() - time >= self.timeout:
            yield()
            print("yielded")
            time = OS.get_system_time_msecs()
        state = state.resume()
    return state
