# Silk
# Builder class for submitting coroutines to a worker

class_name Silk
extends Reference

const NylonWorker := preload("worker.gd")

var instance
var funcname: String


# Silk.new(instance: Object, funcname: String)
# instance (Object): The object to call the method of
# func_name (String): The method name to call
func _init(instance, funcname := "call_func"):
	if instance is WeakRef:
		self.instance = WeakCallable.new(instance, funcname)
		self.funcname = "call_func"
	else:
		self.instance = instance
		self.funcname = funcname


# batch_iter(iter, batch_size : int) -> Silk
func batch_iter(iter, batch_size: int) -> Silk:
	self.instance = BatchIter.new(self.instance, self.funcname, iter, batch_size)
	self.funcname = "call_func"
	return self


# delayed_callable(delay : int) -> Silk
func delayed_callable(delay: int) -> Silk:
	self.instance = DelayedCallable.new(self.instance, self.funcname, delay)
	self.funcname = "call_func"
	return self


# delayed_resume(delay : int) -> Silk
func delayed_resume(delay: int) -> Silk:
	self.instance = DelayedResume.new(self.instance, self.funcname, delay)
	self.funcname = "call_func"
	return self


# frame_callable(frames : int) -> Silk
func frame_callable(frames: int) -> Silk:
	self.instance = FrameCallable.new(self.instance, self.funcname, frames)
	self.funcname = "call_func"
	return self


# frame_resume(frames : int) -> Silk
func frame_resume(frames: int) -> Silk:
	self.instance = FrameResume.new(self.instance, self.funcname, frames)
	self.funcname = "call_func"
	return self


# timed_iter(timeout : int) -> Silk
func timed_iter(iter, timeout: int) -> Silk:
	self.instance = TimedIter.new(self.instance, self.funcname, iter, timeout)
	self.funcname = "call_func"
	return self


# timed_resume(timeout : int) -> Silk
func timed_resume(timeout: int) -> Silk:
	self.instance = TimedResume.new(self.instance, self.funcname, timeout)
	self.funcname = "call_func"
	return self


# submit(worker: NylonWorker, replay: int | bool) -> Coroutine
# replay (int | bool): How many times to call the function
#                      Using `true` repeats until cancelled
func submit(worker: Nylon, retry = 1) -> Coroutine:
	return worker.callv("run_async", build(retry))


func build(retry = 1) -> Array:
	return [self.instance, self.funcname, retry]
