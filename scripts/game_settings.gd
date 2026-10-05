extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_ACTIONS := ["move_up", "move_down", "move_left", "move_right", "interact", "inventory", "pause"]
var mouse_sensitivity := 1.0
var _config := ConfigFile.new()

func _ready() -> void:
	_config.load(SETTINGS_PATH)
	mouse_sensitivity = float(_config.get_value("input", "mouse_sensitivity", 1.0))
	for bus_name in ["Music", "SFX"]:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, float(_config.get_value("audio", bus_name, AudioServer.get_bus_volume_db(bus))))
	for action in DEFAULT_ACTIONS:
		if _config.has_section_key("binds", action):
			var saved = _config.get_value("binds", action)
			if not saved is InputEvent:
				continue
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, saved)

func set_audio(linear_value: float, bus_name: String) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	var db := linear_to_db(maxf(linear_value, 0.001))
	AudioServer.set_bus_volume_db(bus, db)
	_config.set_value("audio", bus_name, db)
	_save()

func get_audio_linear(bus_name: String) -> float:
	var bus := AudioServer.get_bus_index(bus_name)
	return db_to_linear(AudioServer.get_bus_volume_db(bus)) if bus >= 0 else 1.0

func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.1, 3.0)
	_config.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	_save()

func get_mouse_sensitivity() -> float:
	return mouse_sensitivity

func get_action_event(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event
	return null

func set_keybind(action: StringName, key_event: InputEventKey) -> bool:
	if not InputMap.has_action(action) or key_event == null:
		return false
	for other_action in DEFAULT_ACTIONS:
		if other_action == action:
			continue
		for event in InputMap.action_get_events(other_action):
			if event is InputEventKey and event.physical_keycode == key_event.physical_keycode:
				return false
	var replacement := key_event.duplicate() as InputEventKey
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, replacement)
	_config.set_value("binds", action, replacement)
	_save()
	return true

func reset() -> void:
	_config.clear()
	InputMap.load_from_project_settings()
	mouse_sensitivity = 1.0
	for bus_name in ["Music", "SFX"]:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, 0.0)
	_save()

func _save() -> void:
	_config.save(SETTINGS_PATH)
