extends Node


var _tasks : Array[NylonTask] = []
var _run_time := NylonSettings.get_worker_run_timer()
var _skipped := 0
var _duration := 0


func _enter_tree() -> void:
	Performance.add_custom_monitor("Nylon/Tasks", _monitor_task_count)
	Performance.add_custom_monitor("Nylon/Skipped", _monitor_skipped_tasks)
	Performance.add_custom_monitor("Nylon/Duration", _monitor_duration)


## Creates a task from a [Callable] and [NylonConfig].
func create_task(callable: Callable, config := NylonConfig.new()) -> NylonTask:
	var task := NylonTask.new(callable, config)
	_tasks.append(task)
	return task


func _process(_delta: float) -> void:
	var processed_tasks : Array[NylonTask] = []
	var processed_count := 0
	var start := _run_time.get_ticks()
	while not _tasks.is_empty():
		if processed_count > 0 and _tasks[0].is_running() and _run_time.is_elapsed(start):
			break

		var task : NylonTask = _tasks.pop_front()
		task.resume()

		if not task.is_done():
			processed_tasks.push_back(task)
		processed_count += 1

	_skipped = _tasks.size()
	_duration = _run_time.get_ticks() - start

	_tasks.append_array(processed_tasks)


func _monitor_task_count() -> int:
	return _tasks.size()


func _monitor_skipped_tasks() -> int:
	return _skipped


func _monitor_duration() -> int:
	return _duration

