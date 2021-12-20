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

class WeakTest:
    extends Reference

    var count := 0

    func echo():
        count += 1
        print("existing..")

var finished_work := false

func _ready() -> void:
    var test := Test.new()

    var count_job := Worker.run_async(funcref(test, "count_to_10"))
    yield(count_job, "started")
    assert(yield(count_job, "ended") == 10)
    assert(yield(count_job, "completed") == 10)

    var repeat_job := Worker.run_async(funcref(test, "repeat_10_times"), true)
    for _i in range(11):
        yield(repeat_job, "started")
        yield(repeat_job, "ended")
    yield(repeat_job, "completed")

    var loader := InteractiveLoader.new(["icon.png"])
    var load_job := Worker.run_async(funcref(loader, "load_interactive"))
    var res = yield(load_job, "completed")
    print(res)

    var weak := WeakTest.new()
    var weak_callable := WeakCallable.new(weakref(weak), "echo")
    var weak_job := Worker.run_async(funcref(weak_callable, "call_func"), true)
    yield(get_tree().create_timer(.1), "timeout")
    var count := weak.count
    weak = null
    assert(yield(weak_job, "completed") == true)
    assert(count > 0)

    var sum := Sum.new()
    var batch_iter := BatchIter.new([1, 1, 2, 3, 5], funcref(sum, "increment"), 2)
    var batch_job := Worker.run_async(funcref(batch_iter, "call_func"))
    yield(batch_job, "completed")
    assert(sum.count == 12)

    var timed_iter := TimedIter.new([1, 1, 2, 3, 5], funcref(sum, "increment"), 0.01)
    var timed_iter_job := Worker.run_async(funcref(timed_iter, "call_func"))
    yield(timed_iter_job, "completed")
    assert(sum.count == 24)

    print("waiting...")
    var timed_start := TimedResume.new(funcref(self, "print_wait"), 5)
    var timed_resume := TimedCallable.new(funcref(timed_start, "call_func"), 50)
    var timed_job = Worker.run_async(funcref(timed_resume, "call_func"))
    assert(yield(timed_job, "completed") == "result")

    finished_work = true
    print("Finished")

func print_wait():
    print("waited")

    for k in range(30, 40):
        yield()
        print(k)

    return "result"

func _process(_delta: float):
    if not finished_work:
        print("Processing...")
