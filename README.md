# Nylon

A gdscript module that runs coroutines asynchronously.

## Purpose

This library gives the feeling of threads without some of the headaches.

Threading can be used to improve performance or allow running logic seperate from the main loop but in most cases come with their own problems including:
* Lack of [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/threads/thread_safe_apis.html)
* Managing threading primitives [Mutex and Semaphore](https://docs.godotengine.org/en/stable/tutorials/threads/using_multiple_threads.html)
* Not able to use editor break-points for debugging

Nylon makes use of the `yield` keyword which creates a `GDScriptFunctionState` which can be used to `resume` a function. It calls `resume` on each frame which allows users to compute chunks at a time and not hog processing time. It uses the main thread so you avoid issues above with threads but still requires users to chunk work using `yield` to give back control to the main game loop.

## Settings

Settings can be found under the `Nylon` section in the project settings.

![Settings](screenshots/settings.png)

### Add Singleton

Adds a `Worker` singleton. If you prefer to do this on your own or use local nodes then disable this feature.

### Process Timeout

The amount of time (in milliseconds) spent processing coroutines in a single frame.
Nylon uses a round-robin queue to process tasks.
Setting a value of 0 will process 1 task per frame.
Lower numbers may improve frame rates if the queue grows large.

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
See [Silk](#Silk) which uses the builder pattern to create complex jobs.

You can run a function forever by supplying `true` for `retry`. It will run until cancelled which occurs when the coroutine `return true`.

Coroutines emit the following signals:
* `started` when a function is first called at the beginning of each `retry`
* `ended` when a function does not `yield`
  * It returns the latest result of the coroutine
* `completed` when `retry` reaches `0` or the coroutine is cancelled
  * It yields the latest or final result of the coroutine depending if it was cancelled

See [test.gd](https://github.com/mashumafi/nylon/blob/main/test.gd) for more examples. When run you will see the `_process()` function gets called while Nylon is performing other operations.

You can build complex hierarchy of coroutines, here are a few that come with Nylon:

### DelayedCallable

Adds a delay after calling the coroutine. This delay occurs before each retry.

```gdscript
# Update all nodes forever with a 500 millisecond delay between each update
var delayed_callable := DelayedCallable.new(self, "update_nodes", 500)
Worker.run_async(delayed_callable, "call_func", true) # true to repeat forever
```

### DelayedResume

Adds a delay after each `yield`. This allows workers to take breaks between chunks.

```gdscript
# Update 1 node every 50 milliseconds
var delayed_resume := TimedResume.new(self, "update_nodes", 50)
Worker.run_async(delayed_resume, "call_func")
```

### FrameCallable

Waits the requested number of idle frames after calling the coroutine. This delay occurs before each retry.

```gdscript
# Update all nodes forever with a 16 idle frames between each update
var frame_callable := FrameCallable.new(self, "update_nodes", 16)
Worker.run_async(frame_callable, "call_func", true) # true to repeat forever
```

### FrameResume

Waits the requested number of idle frames after each `yield`. This allows workers to take breaks between chunks.

```gdscript
# Update 1 node every 3 frames
var frame_resume := FrameResume.new(self, "update_nodes", 3)
Worker.run_async(frame_resume, "call_func")
```

### TimedResume

Processes a coroutine and `yield` control after `timeout`.

```gdscript
# Update nodes for 3 milliseconds of each frame.
var timed_resume := TimedResume.new(self, "update_nodes", 3)
Worker.run_async(delayed_retimed_resumesume, "call_func")
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

Call the provided function on each item in `iterator` in chunks based on `batch_size`.

```gdscript
# Update 2 nodes per frame
var batch_iter := BatchIter.new(get_children(), self, "update_child", 2)
Worker.run_async(batch_iter, "call_func")
```

#### TimedIter

Call the provided function on each item in `iterator` in chunks based on `timeout`.

```gdscript
# Update nodes for 2 milliseconds each frame
var timed_iter := TimedIter.new(get_children(), self, "update_child", 2)
Worker.run_async(timed_iter, "call_func")
```

### Callable

A custom implementation of `FuncRef`. The main benefit of `Callable` is it will increment the refrence counter for instances passed in.

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
var delayed_weak := WeakCallable.new(weakref(self), "print_wait")
var delayed_resume := DelayedResume.new(delayed_weak, "call_func", 5)
var delayed_start := DelayedCallable.new(delayed_resume, "call_func", 50)
Worker.run_async(delayed_start, "call_func", 3)
```

into the following:

```gdscript
Silk.new(weakref(self), "print_wait") \ # the base function
  .delayed_resume(5) \ # wait 5 milliseconds after each yield
  .delayed_callable(50) \ # wait 50 milliseconds before each retry
  .submit(Worker, 3) # tell worker to run the job three times async
```

Always remember that jobs are evaluated from bottom to top. In the above example it would be:
1. `delayed_callable`
2. `delayed_resume`
3. `print_wait`

Passing a `WeakRef` into the contructor of `Silk` will create a `WeakCallable` and will automatically destroy the Nylon job when the instance is freed. Every other instance type will be handled normally meaning Nylon will contribute to the use count of `Reference` and you must manually cancel jobs using an `Object` before freeing them.
