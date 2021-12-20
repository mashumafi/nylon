# TimedResume
# Adds a delay after yielding from a coroutine

class_name TimedResume
extends Reference

var callable : FuncRef
var timeout := 0

# TimedResume.new(callable: FuncRef, timeout : int)
# callable (FuncRef): The function to call
# timeout (int): Time in milliseconds to wait after yielding
func _init(callable: FuncRef, timeout := 0):
    self.callable = callable
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
