extends Resource

const ADD_SINGLETON := "nylon/add_singleton"
const ADD_SINGLETON_DEFAULT := true
const PROCESS_TIMEOUT := "nylon/process_timeout"
const PROCESS_TIMEOUT_DEFAULT := 3


static func enum_to_hint(enumeration: Dictionary) -> String:
	return PoolStringArray(enumeration.keys()).join(",")


static func create_project_settings() -> void:
	create_project_setting(ADD_SINGLETON, ADD_SINGLETON_DEFAULT)
	create_project_setting(PROCESS_TIMEOUT, PROCESS_TIMEOUT_DEFAULT)


static func clear_project_settings() -> void:
	ProjectSettings.clear(ADD_SINGLETON)
	ProjectSettings.clear(PROCESS_TIMEOUT)


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


static func get_add_singleton() -> bool:
	return get_setting(ADD_SINGLETON, ADD_SINGLETON_DEFAULT)


static func get_process_timeout() -> int:
	return get_setting(PROCESS_TIMEOUT, PROCESS_TIMEOUT_DEFAULT)
