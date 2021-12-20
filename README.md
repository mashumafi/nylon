# Nylon

A gdscript module that runs coroutines asynchronously.

## Purpose

This library gives the feeling of threads without some of the headaches.

Threading can be used to improve performance or allow running logic seperate from the main loop but in most cases come with their own problems including:
* Lack of [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/threads/thread_safe_apis.html)
* Managing threading primitives [Mutex and Semaphore](https://docs.godotengine.org/en/stable/tutorials/threads/using_multiple_threads.html)
* Not able to use editor break-points for debugging

Nylon makes use of the `yield` keyword which creates a `GDScriptFunctionState` which can be used to `resume` a function. It calls `resume` on each frame which allows users to compute chunks at a time and not hog processing time. It uses the main thread so you avoid issues above with threads but still requires users to chunk work to gain a benefit in performance.

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
    Worker.run_async(funcref(self, "update_nodes"))
```

Now Nylon will now update 1 node over the next hundred frames which could improve the user experience.

## Usage

The main entry point for Nylon is the function `Worker.run_async(coroutine, retry)`.
It is recommended to add `Worker` as a autoload singleton depending on your workflow.
It takes only the coroutine which is a `funcref` and how many times to run that function.

You can run a function forever by supplying `true` for `retry`. It will run until cancelled which occurs when the coroutine returns `true`.

Coroutines emit the following signals:
* `started` when a function is first called at the beginning of each `retry`
* `ended` when a function does not `yield`
  * It returns the current result of the coroutine
* `completed` when `retry` reaches `0` or the coroutine is cancelled
  * It yields the final result of the coroutine

See `test.gd` for more examples. When run you will see the `_process()` function gets called while Nylon is performing other operations.

You can build complex hierarchy of coroutines, here are a few that come with Nylon:

### TimedCallable

Adds a delay before calling the coroutine. This delay occurs before each retry.
This works similar to `get_tree().create_timer(timeout)` or the `Timer` class.

### TimedResume

Adds a delay after each `yield`. This allows workers to take breaks between chunks.

### WeakCallable

Safely call coroutines of a `WeakRef`.

## Future

The goal is to extend Nylon to support flexible and easy to build coroutines with it's core.
It would also make sense to add some common generic features such as a resource loaders.