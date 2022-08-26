## A task managed by Nylon.
##
## Should not be created directly,
## instead create tasks with [code]NylonWorker.create_task(...)[/code].
class_name NylonTask
extends RefCounted


## An object used to cancel a [NylonTask].
## [code]return[/code] it from a job you want to cancel.
## [codeblock]
## func job(resume):
##     return NylonTask.Cancel.new()
## [/codeblock]
class Cancel:
	extends Object

## Will emit once the task is completes.
## Check [method is_done] to determine if the task was completed successfully.
## [method get_result] will return the final result of the task.
signal finished()
## Nylon's way of giving permission to resume processing.
## Use [code]await resumed[/code] to ask for permission.
signal resumed()


## State of the task.
enum State {
	READY, ## the job will start when [method resume] is called.
	RUNNING, ## the job has started and will continue processing when [method resume] is called.
	WAIT_RESUME, ## the job will continue processing after waiting.
	WAIT_REPEAT, ## the job will begin processing after waiting.
	DONE ## [method resume] no longer does anything.
}


var _job : Callable
var _config : NylonConfig
var _state := State.READY
var _repeats := 0
var _wait_start : float
var _result = null


## Create a task.[br]
## [code]job[/code] is a function which takes 1 argument. The argument is a [Signal] that can be used to pause processing.[br]
## [code]config[/code] is used to configure the job.[br]
## You can cancel a task by returning [NylonTask.Cancel] from [code]job[/code].
## A task will block the main game loop. It is up to you to [code]await resume[/code] to give back control to your game.
## [codeblock]
## func job(resume):
##    for enemy in enemies:
##        await resume # Ask Nylon for permission to continue
##        enemy.process_ai()
## [/codeblock]
func _init(job: Callable, config := NylonConfig.new()):
	_job = job
	_config = config


## Updates the task's state.
## Resume processing the task when it's ready.
## The state will change only once when called.
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
			@warning_ignore(redundant_await)
			_result = await _job.call(resumed)

			@warning_ignore(unsafe_cast)
			var _cancel := _result as Cancel
			if _cancel:
				_cancel.free()
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
