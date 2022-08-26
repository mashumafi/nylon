class_name NylonSettings
extends RefCounted


const WORKER_RUN_TIMEOUT := "nylon/worker/run_timeout"
const WORKER_RUN_TIMEOUT_DEFAULT := 3.0
const WORKER_RUN_TIMESCALE := "nylon/worker/run_timescale"
const WORKER_RUN_TIMESCALE_DEFAULT := NylonConfig.Timed.TimeScale.MILLISECONDS


class StringConversion:
	func snake_to_pascal(s: String) -> String:
		var next_upper := true
		var output := ""
		for c in s:
			var ch : String = c
			if ch == "_":
				next_upper = true
				continue
			output += ch.to_upper() if next_upper else ch.to_lower()
			next_upper = false
		return output


static func enum_to_hint(enumeration: Dictionary) -> String:
	var conversion := StringConversion.new()
	return ",".join(enumeration.keys().map(conversion.snake_to_pascal))


static func timescale_to_enum_hint() -> String:
	return enum_to_hint(NylonConfig.Timed.TimeScale)


static func create_project_settings() -> void:
	create_project_setting(WORKER_RUN_TIMEOUT, WORKER_RUN_TIMEOUT_DEFAULT)
	create_project_setting(WORKER_RUN_TIMESCALE, WORKER_RUN_TIMESCALE_DEFAULT, PROPERTY_HINT_ENUM, timescale_to_enum_hint())


static func clear_project_settings() -> void:
	ProjectSettings.clear(WORKER_RUN_TIMEOUT)
	ProjectSettings.clear(WORKER_RUN_TIMESCALE)


static func create_project_setting(
	name: String, default, hint: int = PROPERTY_HINT_NONE, hint_string := ""
) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default)

	ProjectSettings.set_initial_value(name, default)
	var info = {
		"name": name,
		"type": typeof(default),
		"hint": hint,
		"hint_string": hint_string,
	}
	ProjectSettings.add_property_info(info)


static func get_setting(name: String, default):
	if ProjectSettings.has_setting(name):
		return ProjectSettings.get_setting(name)
	return default


static func get_worker_run_timeout() -> float:
	return get_setting(WORKER_RUN_TIMEOUT, WORKER_RUN_TIMESCALE_DEFAULT)


static func get_worker_run_timescale() -> int:
	return get_setting(WORKER_RUN_TIMESCALE, WORKER_RUN_TIMESCALE_DEFAULT)


static func get_worker_run_timer() -> NylonConfig.Timed:
	var time := NylonConfig.Timed.new(get_worker_run_timeout())
	time.set_timescale(get_worker_run_timescale())
	return time
