# Silk
# Builder class for submitting coroutines to a worker

class_name Silk
extends Reference

const NylonWorker := preload("../core/worker.gd")
const INSTANCE := "instance"
const FUNCNAME := "funcname"

var _builder := {}

func callable(instance, funcname: String) -> Silk:
    _builder[INSTANCE] = instance
    _builder[FUNCNAME] = funcname
    return self

func weak_callable(instance: WeakRef, funcname: String) -> Silk:
    _builder[INSTANCE] = WeakCallable.new(instance, funcname)
    _builder[FUNCNAME] = "call_func"
    return self

func batch_iter(iter) -> Silk:
    _builder[INSTANCE] = BatchIter.new(_builder[INSTANCE], _builder[FUNCNAME], iter)
    _builder[FUNCNAME] = "call_func"
    return self

func timed_callable(timeout: int) -> Silk:
    _builder[INSTANCE] = TimedCallable.new(_builder[INSTANCE], _builder[FUNCNAME], timeout)
    _builder[FUNCNAME] = "call_func"
    return self

func timed_iter(iter, timeout: int) -> Silk:
    _builder[INSTANCE] = TimedIter.new(_builder[INSTANCE], _builder[FUNCNAME], iter, timeout)
    _builder[FUNCNAME] = "call_func"
    return self

func timed_resume(timeout: int) -> Silk:
    _builder[INSTANCE] = TimedResume.new(_builder[INSTANCE], _builder[FUNCNAME], timeout)
    _builder[FUNCNAME] = "call_func"
    return self

func submit(worker: NylonWorker, retry = 1) -> Coroutine:
    return worker.run_async(_builder[INSTANCE], _builder[FUNCNAME], retry)
