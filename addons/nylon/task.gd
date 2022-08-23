## A task managed by Nylon.
## Should not be created directly,
## instead create tasks with [code]NylonWorker.create_task(...)[/code].
class_name NylonTask
extends RefCounted


## An object used to cancel a [code]NylonTask[/code]
## [code]return[/code] it from a job you want to cancel.
class Cancel:
	extends Object

## Will emit once the task is completes.
## Check `is_done` to determine if the task was completed successfully.
signal finished()
## Nylon's way of giving permission to resume processing.
## Use [code]await resumed[/code] to wait for permission.
signal resumed()


## State of the task.
## [code]READY[/code] means the job will start when [code]resume[/code] is called.
## [code]RUNNING[/code] means the job has started and will continue processing when [code]resume[/code] is called.
## [code]WAIT_REPEAT[/code] means the job will start again after waiting.
## [code]WAIT_RESUME[/code] means the job will continue after waiting.
## [code]DONE[/code] means [code]resume[/code] no longer does anything.
enum State {READY, RUNNING, WAIT_RESUME, WAIT_REPEAT, DONE}


var _job : Callable
var _config : NylonConfig
var _state := State.READY
var _repeats := 0
var _wait_start : float
var _result = null


## Create a task
## [code]job[/code] is a function which takes 1 argument. The argument is a [code]Signal[/code] that can be used to pause processing.
## [code]config[/code] is used to configure the job.
func _init(job: Callable, config := NylonConfig.new()):
	_job = job
	_config = config


## Updates the task's state.
## Resume processing the task when it's ready.
func resume():
	if _state == State.DONE:
		return

	if not _job.is_valid():
		finished.emit()
		_state = State.DONE
		return

	match _state:
		State.READY:
			_state = State.RUNNING
			await resumed # Don't start processing right away
			_result = await _job.call(resumed)

			if _result is Cancel:
				_result.free()
				_result = null
				finished.emit()
				_state = State.DONE
				return

			# Job finished
			_repeats += 1
			
			if _config._repeat.is_valid(_repeats):
				_state = State.WAIT_REPEAT
				_wait_start = _config._repeat_after.get_ticks()
			else:
				_state = State.DONE
				finished.emit()

		State.WAIT_RESUME:
			if _config._resume_after.is_elapsed(self._wait_start):
				_state = State.RUNNING

		State.WAIT_REPEAT:
			if _config._repeat_after.is_elapsed(self._wait_start):
				_state = State.READY

		State.RUNNING:
			var start := _config._run_for.get_ticks()
			resumed.emit()
			while not _config._run_for.is_elapsed(start) and _state == State.RUNNING:
				resumed.emit()

			if _state == State.RUNNING: # Did state change?
				_state = State.WAIT_RESUME
				_wait_start = _config._resume_after.get_ticks()


## Get the latest result of the task.
func get_result():
	return _result


## Checks if the task will do work if you call resume.
func is_running() -> bool:
	return _state == State.READY or _state == State.RUNNING


## Checks if the task is idle
func is_waiting() -> bool:
	return _state == State.WAIT_RESUME or _state == State.WAIT_REPEAT


## Checks if the task has finished.
func is_done() -> bool:
	return _state == State.DONE


## Immediately cancels the task.
func cancel():
	if _state != State.DONE:
		finished.emit()
	_state = State.DONE


## Stops the task from repeating.
func stop():
	_config.repeat(0)
