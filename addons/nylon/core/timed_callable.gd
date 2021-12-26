# TimedCallable
# Adds a delay before calling a coroutine
# Similar to get_tree().create_timer(timeout)

class_name TimedCallable
extends Reference

const Callable := preload("callable.gd")

var callable : Callable
var timeout := 0

# TimedCallable.new(instance: Object, funcname: String, timeout : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# timeout (int): Time in milliseconds to wait before calling the function
func _init(instance, funcname: String, timeout := 0):
    self.callable = Callable.new(instance, funcname)
    self.timeout = timeout

# call_func()
# Calls the function after `timeout` elapses
func call_func():
    var time := OS.get_system_time_msecs()
    while OS.get_system_time_msecs() - time < self.timeout:
        yield()

    return self.callable.call_func()
