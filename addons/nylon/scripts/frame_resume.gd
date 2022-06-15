# FrameResume
# Waits the requested number of idle frames after yielding from a coroutine

class_name FrameResume
extends Reference

const Callable := preload("callable.gd")

var callable: Callable
var frames: int


# FrameResume.new(instance: Object, funcname: String, frames : int)
# instance (Object): object to call a function
# funcname (String): name of the function to call
# frames (int): Number of idle frames to wait after yielding
func _init(instance, funcname: String, frames: int):
	self.callable = Callable.new(instance, funcname)
	self.frames = frames


# call_func():
# Resumes the function after `frames` idle frames has pass
func call_func():
	var state = self.callable.call_func()
	while state is GDScriptFunctionState:
		var target_frames := Engine.get_idle_frames() + self.frames
		while Engine.get_idle_frames() < target_frames:
			yield()
		state = state.resume()
	return state
