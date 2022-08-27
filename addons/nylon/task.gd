## A task managed by Nylon.
##
## Should not be created directly,
## instead create tasks with [code]NylonWorker.create_task(...)[/code].
class_name NylonTask
extends RefCounted

## Will emit once the task is completes.
## Check [method is_done] to determine if the task was completed successfully.
## [method get_result] will return the final result of the task.
signal finished()


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
var _runner := NylonRunner.new()


## Create a task.[br]
## [code]job[/code] is a function which takes 1 argument. The argument is a [NylonRunner] that can be used to pause processing.[br]
## [code]config[/code] is used to configure the job.[br]
## You can cancel a task by calling [method NylonRunner.cancel].
## A task will block the main game loop. It is up to you to [code]await runner.resumed[/code] to give back control to your game.
## [codeblock]
## func job(runner: NylonRunner):
##    for enemy in enemies:
##        await runner.resumed # Ask Nylon for permission to continue
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
			await _runner.resumed # Don't start processing right away
			@warning_ignore(redundant_await)
			_result = await _job.call(_runner)

			if _runner.cancelled:
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
			_runner.resumed.emit()
			while not _config._run_for.is_elapsed(start) and _state == State.RUNNING:
				_runner.resumed.emit()

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
