# TimedIter
# Processes an iterator in chunks based on `timeout`

class_name TimedIter
extends Reference

var iterator
var callable: FuncRef
var timeout := 0

# TimedIter.new(iterator: Iterator, callable: FuncRef, timeout : int)
# iterator (Iterator): The iterator to call functions on
# callable (FuncRef): The method to call
# timeout (int): Time in milliseconds to spend processing
func _init(iterator, callable: FuncRef, timeout := 0):
    self.iterator = iterator
    self.callable = callable
    self.timeout = timeout

# call_func()
# Call `callable` on each item in `iterator` in chunks based on `timeout`
func call_func():
    var end_time := OS.get_system_time_msecs() + timeout
    for item in iterator:
        var result = callable.call_func(item)
        while result is GDScriptFunctionState:
            result = result.resume()
            if OS.get_system_time_msecs() >= end_time:
                yield()
                end_time = OS.get_system_time_msecs() + timeout
        if OS.get_system_time_msecs() >= end_time:
            yield()
            end_time = OS.get_system_time_msecs() + timeout
