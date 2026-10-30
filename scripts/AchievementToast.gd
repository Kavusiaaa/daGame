extends Control

signal dismissed

@export_range(1.0, 12.0, 0.5) var display_seconds: float = 4.0

@onready var _panel: NinePatchRect = $Panel
@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _description: Label = %Description

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func show_achievement(achievement: AchievementResource) -> void:
	visible = true
	_title.text = achievement.title
	_description.text = achievement.description
	_icon.texture = achievement.icon
	var viewport_size := get_viewport().get_visible_rect().size
	var target := Vector2(viewport_size.x - 374.0, 24.0)
	_panel.position = Vector2(viewport_size.x + 8.0, 24.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "position", target, 0.35)
	await tween.finished
	await get_tree().create_timer(display_seconds).timeout
	var exit_tween := create_tween()
	exit_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(_panel, "position:x", viewport_size.x + 8.0, 0.3)
	await exit_tween.finished
	dismissed.emit()
	queue_free()
