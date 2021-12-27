# Nylon

A gdscript module that runs coroutines asynchronously.

## Purpose

This library gives the feeling of threads without some of the headaches.

Threading can be used to improve performance or allow running logic seperate from the main loop but in most cases come with their own problems including:
* Lack of [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/threads/thread_safe_apis.html)
* Managing threading primitives [Mutex and Semaphore](https://docs.godotengine.org/en/stable/tutorials/threads/using_multiple_threads.html)
* Not able to use editor break-points for debugging

Nylon makes use of the `yield` keyword which creates a `GDScriptFunctionState` which can be used to `resume` a function. It calls `resume` on each frame which allows users to compute chunks at a time and not hog processing time. It uses the main thread so you avoid issues above with threads but still requires users to chunk work using `yield` to give back control to the main game loop.

## Example

Say you have the following function which when called users will see a noticeable number of frames dropped.

```gdscript
func update_nodes():
    for child in get_children():
        update_child(child) # performance bottle-neck
```

The performance issue could be due to having hundreds of nodes to update. If this update could occur in the background and infrequently it might be worth using Nylon to perform the work. Using Nylon this function could be refactored like so:

```gdscript
func update_nodes():
    for child in get_children():
        update_child(child)
        yield()
```

It can then be run async by nylon with the following call:

```gdscript
func submit_update():
    Worker.run_async(self, "update_nodes")
```

Now Nylon will now update 1 node over the next hundred frames which could improve the user experience.

## Usage

The main entry point for Nylon is the function `Worker.run_async(instance, funcname, retry)`.
It is recommended to add `Worker` as a autoload singleton depending on your workflow.
It takes only the instace/funcname and how many times to run that function.

You can run a function forever by supplying `true` for `retry`. It will run until cancelled which occurs when the coroutine returns `true`.

Coroutines emit the following signals:
* `started` when a function is first called at the beginning of each `retry`
* `ended` when a function does not `yield`
  * It returns the current result of the coroutine
* `completed` when `retry` reaches `0` or the coroutine is cancelled
  * It yields the final result of the coroutine

See [test.gd](https://github.com/mashumafi/nylon/blob/main/test.gd) for more examples. When run you will see the `_process()` function gets called while Nylon is performing other operations.

You can build complex hierarchy of coroutines, here are a few that come with Nylon:

### TimedCallable

Adds a delay before calling the coroutine. This delay occurs before each retry.
This works similar to `get_tree().create_timer(timeout)` or the `Timer` class.

```gdscript
# Update 1 node per frame after a 500 millisecond delay
var timed_callable := TimedCallable.new(self, "update_nodes", 500)
Worker.run_async(timed_callable, "call_func")
```

### TimedResume

Adds a delay after each `yield`. This allows workers to take breaks between chunks.

```gdscript
# Update 1 node every 50 milliseconds
var timed_resume := TimedResume.new(self, "update_nodes", 50)
Worker.run_async(timed_resume, "call_func")
```

### WeakCallable

Safely call coroutines of a `WeakRef`.

```gdscript
# Update nodes until `self` is no longer valid
var weak_callable := WeakCallable.new(weakref(self), "update_nodes")
Worker.run_async(weak_callable, "call_func")
```

### Iterators

The Iter classes take an iterator and performs small amounts of work at a time. They take an iterator and a instance/funcname, the function should take 1 argument. With the above example you can call `update_child` directly.

#### BatchIter

Call the provided function on each item in `iterator` in chunks based on `batch_size`

```gdscript
# Update 2 nodes per frame
var batch_iter := BatchIter.new(get_children(), self, "update_child", 2)
Worker.run_async(batch_iter, "call_func")
```

#### TimedIter

Call the provided function on each item in `iterator` in chunks based on `timeout`

```gdscript
# Update nodes until 2 milliseconds elapse
var timed_iter := TimedIter.new(get_children(), self, "update_child", 2)
Worker.run_async(timed_iter, "call_func")
```

### Callable

The custom implementation of `FuncRef`. The main benefit of `Callable` is it will increment the refrence counter for instances passed in.

### Cancelling

You may want to cancel existing coroutines for reasons such as:
* Stop them from running forever
* The result is no longer needed

Nylon will stop processing a coroutine if at any point it returns exactly `true`.
Another option is to use the `cancel` method on `Coroutine` which is returned by `Worker.run_async(instance, funcname, retry)`.
`cancel` can be used to stop processing entirely or to allow processing to finish resuming a function to it's final result.

```gdscript
var job := Worker.run_async(instance, funcname, retry)
job.cancel(true) # Allow job to finish resuming, emits `ended` once finished but never emits `completed`
job.cancel(false) # Immediately terminates a job, emits `ended` once called and `completed` emits on the next frame
```

## Silk

The `Silk` class simplifies complex Nylon tasks using the builder pattern.

It can transform a redundant expression like:

```gdscript
var timed_weak := WeakCallable.new(weakref(self), "print_wait")
var timed_resume := TimedResume.new(timed_weak, "call_func", 5)
var timed_start := TimedCallable.new(timed_resume, "call_func", 50)
Worker.run_async(timed_start, "call_func", 1)
```

into the following:

```gdscript
Silk.new(self, "print_wait") \ # the base function
  .timed_resume(5) \ # wait 5 milliseconds after each yield
  .timed_callable(50) \ # wait 50 milliseconds before each retry
  .submit(Worker, 1) # tell worker to run the job once async
```

Always remember that jobs are evaluated from bottom to top. In the above example it would be:
1. `timed_callable`
2. `timed_resume`
3. `print_wait`

Silk will always convert the instance passed into it's constructor into a `WeakRef`/`WeakCallable` which will automatically destroy the job if the object ever gets freed.
