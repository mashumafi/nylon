extends Node


var _tasks : Array[NylonTask] = []


## Adds a task to Nylon.
func add_task(task: NylonTask) -> void:
	_tasks.append(task)


## Creates a task from a [code]Callable[/code] and [code]NylonConfig[/code].
func create_task(callable: Callable, config := NylonConfig.new()) -> NylonTask:
	var task := NylonTask.new(callable, config)
	add_task(task)
	return task


func get_ticks(timescale: int) -> float:
	var time := NylonConfig.Timed.new()
	match timescale:
		NylonSettings.TimeScale.MICROSECONDS:
			time.microseconds()
		NylonSettings.TimeScale.MILLISECONDS:
			time.milliseconds()
		NylonSettings.TimeScale.SECONDS:
			time.seconds()
		NylonSettings.TimeScale.MINUTES:
			time.minutes()
		NylonSettings.TimeScale.HOURS:
			time.hours()
		NylonSettings.TimeScale.DAYS:
			time.days()
	return time.get_ticks()


func get_run_ticks() -> float:
	return get_ticks(NylonSettings.get_worker_run_timescale())


func _process(_delta: float) -> void:
	var processed_tasks : Array[NylonTask] = []
	var processed_count := 0
	var start := get_run_ticks()
	while not _tasks.is_empty():
		if processed_count > 0 and _tasks.front().is_running() and get_run_ticks() - start > NylonSettings.get_worker_run_timeout():
			print_debug("Nylon task load is heavy, will continue processing next frame")
			break

		var task : NylonTask = _tasks.pop_front()
		task.resume()

		if not task.is_done():
			processed_tasks.push_back(task)
		processed_count += 1

	_tasks.append_array(processed_tasks)
