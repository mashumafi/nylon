extends Node


func do_work(resume: Signal):
	for i in 10:
		print(i)
		OS.delay_msec(10)
		await resume


func do_more_work(resume: Signal):
	for i in range(10, 20):
		print(i)
		OS.delay_msec(10)
		await resume


class Temp:
	extends RefCounted

	func do_work(resume: Signal):
		for i in 10:
			print(i)
			OS.delay_msec(10)
			await resume


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
	config.resume_after(120).frames()
	task = NylonWorker.create_task(do_more_work, config)
	await task.finished

	var temp := Temp.new()
	config = NylonConfig.new()
	config.repeat(-1)
	NylonWorker.create_task(temp.do_work, config)
	await get_tree().create_timer(1).timeout

	#get_tree().quit()