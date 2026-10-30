extends Node

signal achievement_unlocked(achievement: AchievementResource)

# Editor workflow: create a Resource in res://data/achievements, choose AchievementResource,
# set a unique ID, title, description and pixel-art icon, then save it as a .tres.
# If its ID is first_door, any gameplay script can unlock it with AchievementManager.unlock_achievement("first_door").

const ACHIEVEMENTS_DIR := "res://data/achievements"
const SAVE_PATH := "user://achievements.cfg"
const TOAST_SCENE: PackedScene = preload("res://AchievementToast.tscn")
const PANEL_SCENE: PackedScene = preload("res://AchievementPanel.tscn")

var achievements: Dictionary = {}
var _ui_layer: CanvasLayer
var _panel: Control
var _toast_queue: Array[AchievementResource] = []
var _toast_active := false
var _previous_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_achievements()
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "AchievementUILayer"
	_ui_layer.layer = 90
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_layer)
	_panel = PANEL_SCENE.instantiate() as Control
	_ui_layer.add_child(_panel)
	achievement_unlocked.connect(_on_achievement_unlocked)

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("achievements"):
		_toggle_panel()
		get_viewport().set_input_as_handled()
	elif _panel != null and _panel.visible and event.is_action_pressed("pause"):
		_close_panel()
		get_viewport().set_input_as_handled()

func register_achievement(achievement: AchievementResource) -> void:
	if achievement == null or achievement.id.is_empty():
		push_warning("Cannot register an achievement without a resource and ID.")
		return
	achievements[achievement.id] = achievement

func unlock_achievement(achievement_id: String) -> void:
	var achievement := achievements.get(achievement_id) as AchievementResource
	if achievement == null:
		push_warning("Unknown achievement ID: %s" % achievement_id)
		return
	if achievement.unlocked:
		return
	achievement.unlocked = true
	_save_unlocked()
	achievement_unlocked.emit(achievement)

func is_unlocked(achievement_id: String) -> bool:
	var achievement := achievements.get(achievement_id) as AchievementResource
	return achievement != null and achievement.unlocked

func _load_achievements() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var directory := DirAccess.open(ACHIEVEMENTS_DIR)
	if directory == null:
		push_warning("Achievement resource directory is missing: %s" % ACHIEVEMENTS_DIR)
		return
	for file_name in directory.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var achievement := load("%s/%s" % [ACHIEVEMENTS_DIR, file_name]) as AchievementResource
		if achievement == null:
			push_warning("Could not load achievement resource: %s" % file_name)
			continue
		achievement.unlocked = bool(config.get_value("unlocked", achievement.id, achievement.unlocked))
		register_achievement(achievement)

func _save_unlocked() -> void:
	var config := ConfigFile.new()
	for achievement_id in achievements:
		var achievement := achievements[achievement_id] as AchievementResource
		config.set_value("unlocked", achievement_id, achievement.unlocked)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save achievements (error %s)." % error)

func _toggle_panel() -> void:
	if _panel.visible:
		_close_panel()
	else:
		_previous_paused = get_tree().paused
		_panel.visible = true
		get_tree().paused = true

func _close_panel() -> void:
	_panel.visible = false
	get_tree().paused = _previous_paused

func _on_achievement_unlocked(achievement: AchievementResource) -> void:
	_toast_queue.append(achievement)
	_show_next_toast()

func _show_next_toast() -> void:
	if _toast_active or _toast_queue.is_empty():
		return
	_toast_active = true
	var achievement: AchievementResource = _toast_queue.pop_front()
	var toast := TOAST_SCENE.instantiate()
	_ui_layer.add_child(toast)
	toast.dismissed.connect(_on_toast_dismissed)
	toast.show_achievement(achievement)

func _on_toast_dismissed() -> void:
	_toast_active = false
	call_deferred("_show_next_toast")
