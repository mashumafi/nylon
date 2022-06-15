# DelayedCallable
# Adds a delay after calling a coroutine

class_name DelayedCallable
extends Reference

const Callable := preload("callable.gd")

var callable: Callable
var delay: int
var last_finished := 0


# DelayedCallable.new(instance: Object, funcname: String, delay : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# delay (int): Time in milliseconds to wait before a retry
func _init(instance, funcname: String, delay: int):
	self.callable = Callable.new(instance, funcname)
	self.delay = delay


# call_func()
# Calls the function after `delay` elapses
func call_func():
	while OS.get_system_time_msecs() < last_finished:
		yield()

	var state = self.callable.call_func()
	while state is GDScriptFunctionState:
		yield()
		state = state.resume()

	last_finished = OS.get_system_time_msecs() + self.delay
	return state
