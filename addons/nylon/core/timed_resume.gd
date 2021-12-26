# TimedResume
# Adds a delay after yielding from a coroutine

class_name TimedResume
extends Reference

const Callable := preload("callable.gd")

var callable : Callable
var timeout := 0

# TimedResume.new(instance: Object, funcname: String, timeout : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# timeout (int): Time in milliseconds to wait after yielding
func _init(instance, funcname: String, timeout := 0):
    self.callable = Callable.new(instance, funcname)
    self.timeout = timeout

# call_func():
# Resumes the function after `timeout` elapses
func call_func():
    var state = self.callable.call_func()
    while state is GDScriptFunctionState:
        var time := OS.get_system_time_msecs()
        while OS.get_system_time_msecs() - time < self.timeout:
            yield()
        state = state.resume()
    return state
