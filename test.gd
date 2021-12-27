extends Node

var InteractiveLoader := preload("res://addons/nylon/common/interactive_loader.gd")

class Test:
    func count_to_10():
        for i in range(10):
            print(i)
            yield()

        return 10

    var j := 20
    func repeat_10_times():
        if j < 30:
            print(j)
            j += 1
            return false

        return true

class Sum:
    var count := 0

    func increment(num: int):
        count += num
        return float(count)

class WeakTest:
    extends Reference

    var count := 0

    func echo():
        count += 1
        print("existing..")

var finished_work := false

func _ready() -> void:
    var test := Test.new()

    var count_job := Worker.run_async(test, "count_to_10")
    yield(count_job, "started")
    assert(yield(count_job, "ended") == 10)
    assert(yield(count_job, "completed") == 10)

    var repeat_job := Worker.run_async(test, "repeat_10_times", true)
    for _i in range(11):
        yield(repeat_job, "started")
        yield(repeat_job, "ended")
    yield(repeat_job, "completed")

    var loader := InteractiveLoader.new(["addons/nylon/icon.png"])
    var load_job := Worker.run_async(loader, "load_interactive")
    var res = yield(load_job, "completed")
    print(res)

    var weak := WeakTest.new()
    var weak_callable := WeakCallable.new(weakref(weak), "echo")
    var weak_job := Worker.run_async(weak_callable, "call_func", true)
    yield(get_tree().create_timer(.1), "timeout")
    var count := weak.count
    weak = null
    assert(yield(weak_job, "completed") == true)
    assert(count > 0)

    var sum := Sum.new()
    var batch_iter := BatchIter.new([1, 1, 2, 3, 5], sum, "increment", 2)
    var batch_job := Worker.run_async(batch_iter, "call_func")
    assert(yield(batch_job, "completed") == 12.0)
    assert(sum.count == 12)

    var cancel_job := Worker.run_async(batch_iter, "call_func")
    yield(cancel_job, "started")
    yield(get_tree(), "idle_frame") # Cannot cancel while handling `started` signal
    cancel_job.cancel(false) # emits `ended`
    assert(yield(cancel_job, "completed") == null) # no result since it was cancelled
    assert(sum.count == 14)

    var cancel_job_wait := Worker.run_async(batch_iter, "call_func")
    yield(cancel_job_wait, "started")
    yield(get_tree(), "idle_frame") # Cannot cancel while handling `started` signal
    cancel_job_wait.cancel(true)
    assert(yield(cancel_job_wait, "ended") == 26.0) # `completed` won't be called
    assert(sum.count == 26)

    var timed_iter := TimedIter.new([1, 1, 2, 3, 5], sum, "increment", 0.01)
    var timed_iter_job := Worker.run_async(timed_iter, "call_func")
    assert(yield(timed_iter_job, "completed") == 38.0)
    assert(sum.count == 38)

    print("waiting...")
    var timed_weak := WeakCallable.new(weakref(self), "print_wait")
    var timed_resume := TimedResume.new(timed_weak, "call_func", 5)
    var timed_start := TimedCallable.new(timed_resume, "call_func", 50)
    var timed_job = Worker.run_async(timed_start, "call_func")
    assert(yield(timed_job, "completed") == "result")

    print("waiting for silk...")
    var silk_timed_job = Silk.new(self, "print_wait") \
        .timed_resume(5) \
        .timed_callable(50) \
        .submit(Worker)
    assert(yield(silk_timed_job, "completed") == "result")

    finished_work = true
    print("Finished")

    var unfinished_job := Worker.run_async(Test.new(), "count_to_10") # Test should live on
    get_tree().connect("idle_frame", self, "wait_for_job", [unfinished_job])

func wait_for_job(unfinished_job: Coroutine):
    assert(yield(unfinished_job, "completed") == 10)

func print_wait():
    print("waited")

    for k in range(30, 40):
        yield()
        print(k)

    return "result"

func _process(_delta: float):
    if not finished_work:
        print("Processing...")
