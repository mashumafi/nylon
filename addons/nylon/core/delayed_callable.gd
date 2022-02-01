# DelayedCallable
# Adds a delay before calling a coroutine
# Similar to get_tree().create_timer(delay)

class_name DelayedCallable
extends Reference

const Callable := preload("callable.gd")

var callable : Callable
var delay := 0

# DelayedCallable.new(instance: Object, funcname: String, delay : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# delay (int): Time in milliseconds to wait before calling the function
func _init(instance, funcname: String, delay := 0):
    self.callable = Callable.new(instance, funcname)
    self.delay = delay

# call_func()
# Calls the function after `delay` elapses
func call_func():
    var time := OS.get_system_time_msecs()
    while OS.get_system_time_msecs() - time < self.delay:
        yield()

    return self.callable.call_func()
