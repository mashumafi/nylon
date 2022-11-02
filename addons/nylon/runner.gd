## Used to control a task.
##
## Check if you should take a break with [signal resumed].
## Cancel the task by calling [method cancel].
class_name NylonRunner
extends RefCounted

## Used to check if you should take a break.
## Use [code]await resumed[/code] to ask.
signal resumed()

## Check if the task is cancelled.
var cancelled := false :
	get:
		return cancelled

## Cancel the task.
func cancel():
	cancelled = true
