# TimedIter
# Processes an iterator in chunks based on `timeout`

class_name TimedIter
extends Reference

const Callable := preload("callable.gd")

var callable: Callable
var iterator
var timeout: int


# TimedIter.new(instance: Object, funcname: String, iterator: Iterator, timeout : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# iterator (Iterator): The iterator to call functions on
# timeout (int): Time in milliseconds to spend processing
func _init(instance, funcname: String, iterator, timeout: int):
	self.callable = Callable.new(instance, funcname)
	self.iterator = iterator
	self.timeout = timeout


# call_func()
# Call `callable` on each item in `iterator` in chunks based on `timeout`
# Returns the final result
func call_func():
	var end_time := OS.get_system_time_msecs() + timeout
	var final_result = null
	for item in iterator:
		var result = callable.call_func([item])
		while result is GDScriptFunctionState:
			result = result.resume()
			if OS.get_system_time_msecs() >= end_time:
				yield()
				end_time = OS.get_system_time_msecs() + timeout
		final_result = result
		if OS.get_system_time_msecs() >= end_time:
			yield()
			end_time = OS.get_system_time_msecs() + timeout
	return final_result
