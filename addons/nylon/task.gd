class_name NylonTask
extends RefCounted


signal finished(cancelled)
signal resumed()


enum {READY, RUNNING, WAIT_RESUME, WAIT_REPEAT, DONE}


var _job : Callable
var _config : NylonConfig
var _state := READY
var _repeats := 0
var _wait_start : float
var _result = null


func _init(job: Callable, config := NylonConfig.new()):
	_job = job
	_config = config


func resume():
	if _state == DONE:
		return

	if not _job.is_valid():
		finished.emit(true)
		_state = DONE
		return

	match _state:
		READY:
			_state = RUNNING
			await resumed # Don't start processing right away
			_result = await _job.call(resumed)

			# Job finished
			_repeats += 1
			
			if _config._repeat.is_valid(_repeats):
				_state = WAIT_REPEAT
				_wait_start = _config._repeat_after.get_ticks()
			else:
				finished.emit(false)
				_state = DONE

		WAIT_RESUME:
			if _config._resume_after.is_elapsed(self._wait_start):
				_state = RUNNING

		WAIT_REPEAT:
			if _config._repeat_after.is_elapsed(self._wait_start):
				_state = READY

		RUNNING:
			var start := _config._run_for.get_ticks()
			resumed.emit()
			while not _config._run_for.is_elapsed(start) and _state == RUNNING:
				resumed.emit()

			if _state == RUNNING: # Did state change?
				_state = WAIT_RESUME
				_wait_start = _config._resume_after.get_ticks()


func get_result():
	return _result


func is_running() -> bool:
	return _state == READY or _state == RUNNING


func is_waiting() -> bool:
	return _state == WAIT_RESUME or _state == WAIT_REPEAT


func is_done() -> bool:
	return _state != DONE


func cancel():
	if _state != DONE:
		finished.emit(true)
	_state = DONE
