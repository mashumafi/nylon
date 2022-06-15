# DelayedResume
# Adds a delay after yielding from a coroutine

class_name DelayedResume
extends Reference

const Callable := preload("callable.gd")

var callable: Callable
var delay: int


# TimedResume.new(instance: Object, funcname: String, delay : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# delay (int): Time in milliseconds to wait after yielding
func _init(instance, funcname: String, delay: int):
	self.callable = Callable.new(instance, funcname)
	self.delay = delay


# call_func():
# Resumes the function after `delay` elapses
func call_func():
	var state = self.callable.call_func()
	while state is GDScriptFunctionState:
		var time := OS.get_system_time_msecs() + self.delay
		while OS.get_system_time_msecs() < time:
			yield()
		state = state.resume()
	return state
