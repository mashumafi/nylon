# FrameCallable
# Waits the requested number of idle frames after calling a coroutine

class_name FrameCallable
extends Reference

const Callable := preload("callable.gd")

var callable: Callable
var frames: int
var target_frames := 0


# FrameCallable.new(instance: Object, funcname: String, frames : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# frames (int): Number of idle frames to wait before a retry
func _init(instance, funcname: String, frames: int):
	self.callable = Callable.new(instance, funcname)
	self.frames = frames


# call_func()
# Calls the function after `frames` idle frames has passed
func call_func():
	while Engine.get_idle_frames() < target_frames:
		yield()

	var state = self.callable.call_func()
	while state is GDScriptFunctionState:
		yield()
		state = state.resume()

	target_frames = Engine.get_idle_frames() + self.frames
	return state
