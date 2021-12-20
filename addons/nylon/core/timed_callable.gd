# TimedCallable
# Adds a delay before calling a coroutine
# Similar to get_tree().create_timer(timeout)

class_name TimedCallable
extends Reference

var callable : FuncRef
var timeout := 0

# TimedCallable.new(callable: FuncRef, timeout : int)
# callable (FuncRef): The function to call
# timeout (int): Time in milliseconds to wait before calling the function
func _init(callable: FuncRef, timeout := 0):
    self.callable = callable
    self.timeout = timeout

# call_func()
# Calls the function after `timeout` elapses
func call_func():
    var time := OS.get_system_time_msecs()
    while OS.get_system_time_msecs() - time < self.timeout:
        yield()

    return self.callable.call_func()
