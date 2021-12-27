# Silk
# Builder class for submitting coroutines to a worker

class_name Silk
extends Reference

const NylonWorker := preload("../core/worker.gd")

var instance
var funcname : String

# Silk.new(instance: Object, funcname: String)
# instance (Object): The object to call the method of
# func_name (String): The method name to call
func _init(instance, funcname: String):
    if instance is WeakRef:
        self.instance = WeakCallable.new(instance, funcname)
        self.funcname = "call_func"
    else:
        self.instance = instance
        self.funcname = funcname

# batch_iter(iter, batch_size : int) -> Silk
func batch_iter(iter, batch_size := 9223372036854775807) -> Silk:
    self.instance = BatchIter.new(self.instance, self.funcname, iter, batch_size)
    self.funcname = "call_func"
    return self

# timed_callable(timeout : int) -> Silk
func timed_callable(timeout: int) -> Silk:
    self.instance = TimedCallable.new(self.instance, self.funcname, timeout)
    self.funcname = "call_func"
    return self

# timed_iter(timeout : int) -> Silk
func timed_iter(iter, timeout: int) -> Silk:
    self.instance = TimedIter.new(self.instance, self.funcname, iter, timeout)
    self.funcname = "call_func"
    return self

# batch_iter(iter, timeout : int) -> Silk
func timed_resume(timeout: int) -> Silk:
    self.instance = TimedResume.new(self.instance, self.funcname, timeout)
    self.funcname = "call_func"
    return self

# submit(worker: NylonWorker, replay: int | bool) -> Coroutine
# replay (int | bool): How many times to call the function
#                      Using `true` repeats until cancelled
func submit(worker: NylonWorker, retry = 1) -> Coroutine:
    return worker.run_async(self.instance, self.funcname, retry)
