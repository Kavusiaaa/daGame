extends Control

const ROW_FRAME: Texture2D = preload("res://assets/achievements/pixel_frame.png")

@onready var _rows: VBoxContainer = %Rows

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	AchievementManager.achievement_unlocked.connect(_refresh)
	_refresh()

func _refresh(_achievement: AchievementResource = null) -> void:
	if not is_node_ready():
		return
	for child in _rows.get_children():
		child.queue_free()
	var ids: Array = AchievementManager.achievements.keys()
	ids.sort()
	for achievement_id in ids:
		var achievement := AchievementManager.achievements[achievement_id] as AchievementResource
		_add_row(achievement)

func _add_row(achievement: AchievementResource) -> void:
	var row := Control.new()
	row.custom_minimum_size = Vector2(0, 92)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_child(row)
	var frame := NinePatchRect.new()
	frame.texture = ROW_FRAME
	frame.patch_margin_left = 6
	frame.patch_margin_top = 6
	frame.patch_margin_right = 6
	frame.patch_margin_bottom = 6
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(frame)
	var icon := TextureRect.new()
	icon.texture = achievement.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(16, 14)
	icon.size = Vector2(64, 64)
	if not achievement.unlocked:
		icon.modulate = Color(0.34, 0.36, 0.40, 1.0)
	row.add_child(icon)
	var title := Label.new()
	title.position = Vector2(94, 13)
	title.size = Vector2(560, 28)
	title.text = achievement.title if achievement.unlocked else "???"
	title.add_theme_color_override("font_color", Color(0.98, 0.83, 0.52) if achievement.unlocked else Color(0.62, 0.63, 0.65))
	title.add_theme_font_size_override("font_size", 20)
	row.add_child(title)
	var description := Label.new()
	description.position = Vector2(94, 43)
	description.size = Vector2(560, 38)
	description.text = achievement.description if achievement.unlocked else "Nie odblokowano"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color(0.88, 0.87, 0.82))
	row.add_child(description)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		var panel := get_node_or_null("Panel") as Control
		if panel:
			panel.position = (get_viewport_rect().size - panel.size) * 0.5
