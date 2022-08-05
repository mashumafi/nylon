# BatchIter
# Processes an iterator in chunks based on `batch_size`

class_name BatchIter
extends Reference

const Callable := preload("callable.gd")

var callable: Callable
var iterator
var batch_size: int


# BatchIter.new(instance: Object, funcname: String, iterator: Iterator, batch_size : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# iterator (Iterator): The iterator to call functions on
# batch_size (int): The max number of items to process per call
func _init(instance, funcname: String, iterator, batch_size: int):
	self.callable = Callable.new(instance, funcname)
	self.iterator = iterator
	self.batch_size = batch_size


# call_func()
# Call `callable` on each item in `iterator` in chunks based on `batch_size`
# If `callable` returns a `GDScriptFunctionState` each `resume` will increment count by 1
# If `callable` returns an `int` then increment the count by that amount
# Returns the final result
func call_func():
	var count := 0
	var final_result = null
	for item in iterator:
		var result = callable.call_func([item])
		while result is GDScriptFunctionState:
			result = result.resume()
			count += 1
			if count >= batch_size:
				yield()
				count = 0
		if result is int:
			count += result
		else:
			final_result = result
			count += 1
		if count >= batch_size:
			yield()
			count = 0
	return final_result
