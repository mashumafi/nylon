extends Node


func do_work(runner: NylonRunner):
	for i in 10:
		print(i)
		OS.delay_msec(10)
		await runner.resumed


func do_more_work(runner: NylonRunner):
	for i in range(10, 20):
		print(i)
		OS.delay_msec(10)
		await runner.resumed


class Temp:
	extends RefCounted

	func do_work(runner: NylonRunner):
		for i in 10:
			print(i)
			OS.delay_msec(10)
			await runner.resumed


func cancelled_function(runner: NylonRunner):
	print("Cancelling")
	runner.cancel()


func _ready():
	var config := NylonConfig.new()
	config.run_for(25).milliseconds()
	config.resume_after(1.5).seconds()
	config.repeat_after(2).seconds()
	config.repeat(2)
	var task := NylonWorker.create_task(do_work, config)
	task = NylonWorker.create_task(do_work, config)
	await task.finished

	config = NylonConfig.new()
	config.run_for(25).milliseconds()
	config.resume_after(120).process_frames()
	task = NylonWorker.create_task(do_more_work, config)
	await task.finished

	var temp := Temp.new()
	config = NylonConfig.new()
	config.repeat(-1)
	NylonWorker.create_task(temp.do_work, config)
	await get_tree().create_timer(1).timeout

	config = NylonConfig.new()
	config.run_for(25).milliseconds()
	config.resume_after(120).process_frames()
	config.repeat(-1)
	task = NylonWorker.create_task(cancelled_function, config)
	await task.finished
	assert(not task.is_done())
	assert(task.get_result() == null)

	print("Ready...")

	#get_tree().quit()
