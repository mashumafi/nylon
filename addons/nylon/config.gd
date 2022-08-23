class_name NylonConfig
extends RefCounted


## Use for computing timespans.
class Timed:
	extends RefCounted


	const SECONDS := 1.0 / 1000.0
	const MINUTES := SECONDS / 60.0
	const HOURS := MINUTES / 60.0
	const DAYS := HOURS / 24.0


	var _time : float
	var _eval : Callable


	func _init(time := 0.0):
		self._time = time
		self.milliseconds()


	## Use microseconds for timescale
	func microseconds():
		_eval = _convert_time.bind(Time.get_ticks_usec, 1)


	## Use milliseconds for timescale
	func milliseconds():
		_eval = _convert_time.bind(Time.get_ticks_msec, 1)


	## Use seconds for timescale
	func seconds():
		_eval = _convert_time.bind(Time.get_ticks_msec, SECONDS)


	## Use minutes for timescale
	func minutes():
		_eval = _convert_time.bind(Time.get_ticks_msec, MINUTES)


	## Use hours for timescale
	func hours():
		_eval = _convert_time.bind(Time.get_ticks_msec, HOURS)


	## Use days for timescale
	func days():
		_eval = _convert_time.bind(Time.get_ticks_msec, DAYS)


	## Gets ticks using the current timescale.
	func get_ticks() -> float:
		return _eval.call()


	## Check if the number of ticks has elapsed.
	func is_elapsed(start: float) -> bool:
		return get_ticks() - start > _time


	func _convert_time(callable: Callable, mult: float):
		return callable.call() * mult


class RunFor:
	extends Timed

	func _init(time := 0.0):
		super(time)


class Delay:
	extends Timed

	func _init(time := 0.0):
		super(time)

	## The number of frames to wait.
	func frames():
		_eval = Engine.get_process_frames


class Repeat:
	extends RefCounted

	var _amount : int

	func _init(amount := -1):
		_amount = amount

	## Checks if the input number is valid to repeat.
	func is_valid(amount: int) -> bool:
		return _amount == -1 or amount < self._amount


var _run_for := RunFor.new(0)
var _resume_after := Delay.new(0)
var _repeat_after := Delay.new(0)
var _repeat := Repeat.new(1)


## How long to run the task.
## Defaults to run for [code]0[/code] milliseconds.
## [code]time[/code] will use milliseconds by default but the timescale can be adjusted with the returned value.
func run_for(time: float) -> RunFor:
	_run_for._time = time
	return _run_for


## How long to wait before resuming the task.
## Defaults to resume after [code]0[/code] milliseconds.
## [code]time[/code] will use milliseconds by default but the timescale can be adjusted with the returned value.
func resume_after(time: float) -> Delay:
	_resume_after._time = time
	return _resume_after


## How long to wait before repeating the task.
## Defaults to wait [code]0[/code] milliseconds.
## [code]time[/code] will use milliseconds by default but the timescale can be adjusted with the returned value.
func repeat_after(time: float) -> Delay:
	_repeat_after._time = time
	return _repeat_after


## How many times to repeat the task.
## By default tasks only run [code]1[/code] time.
## [code]-1[/code] will run a task forever.
func repeat(amount := -1) -> Repeat:
	_repeat._amount = amount
	return _repeat
