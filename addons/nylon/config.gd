class_name NylonConfig
extends RefCounted


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


	func microseconds():
		_eval = _convert_time.bind(Time.get_ticks_usec, 1)


	func milliseconds():
		_eval = _convert_time.bind(Time.get_ticks_msec, 1)


	func seconds():
		_eval = _convert_time.bind(Time.get_ticks_msec, SECONDS)


	func minutes():
		_eval = _convert_time.bind(Time.get_ticks_msec, MINUTES)


	func hours():
		_eval = _convert_time.bind(Time.get_ticks_msec, HOURS)


	func days():
		_eval = _convert_time.bind(Time.get_ticks_msec, DAYS)


	func get_ticks() -> float:
		return _eval.call()


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

	func frames():
		_eval = Engine.get_process_frames


class Repeat:
	extends RefCounted

	var _amount : int

	func _init(amount := -1):
		_amount = amount

	func is_valid(amount: int) -> bool:
		return _amount == -1 or amount < self._amount


var _run_for := RunFor.new(0)
var _resume_after := Delay.new(0)
var _repeat_after := Delay.new(0)
var _repeat := Repeat.new(1)


func run_for(time: float) -> RunFor:
	_run_for._time = time
	return _run_for


func resume_after(time: float) -> Delay:
	_resume_after._time = time
	return _resume_after


func repeat_after(time: float) -> Delay:
	_repeat_after._time = time
	return _repeat_after


func repeat(amount := -1) -> Repeat:
	_repeat._amount = amount
	return _repeat
