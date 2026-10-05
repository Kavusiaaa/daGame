extends CanvasLayer

const ItemDefinition = preload("res://scripts/inventory_item.gd")
const PANEL_BG := Color(0.10, 0.12, 0.15, 0.97)
const SLOT_BG := Color(0.16, 0.19, 0.22, 1.0)
const ACCENT := Color(0.82, 0.68, 0.42, 1.0)

var _toggle: Button
var _panel: PanelContainer
var _grid: GridContainer
var _empty: Label
var _collectibles_tab: Button
var _gameplay_tab: Button
var _details_title: Label
var _details_description: Label
var _selected_category := ItemDefinition.Category.COLLECTIBLE
var _selected_item_id: StringName = &""
var _player: Node
var _lock_held := false

func _ready() -> void:
	layer = 80
	_build_ui()
	get_viewport().size_changed.connect(_resize_panel)
	_resize_panel()
	InventoryManager.inventory_changed.connect(_refresh)
	InventoryManager.item_added.connect(_on_item_added)
	_refresh()

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var dialog_open := DialogueManager.is_active()
	_toggle.visible = is_instance_valid(player) and not dialog_open
	if is_instance_valid(_player) and _player != player:
		_release_lock()
	if _panel.visible and (not is_instance_valid(player) or dialog_open):
		_close_panel()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo() and not DialogueManager.is_active() and not get_tree().paused:
		get_viewport().set_input_as_handled()
		_toggle_panel()

func _build_ui() -> void:
	# The Inventory autoload is a CanvasLayer, so this full-rect overlay is
	# anchored to the viewport and never inherits a world/camera transform.
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(overlay)
	_toggle = Button.new()
	_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toggle.position = Vector2(-74, 18)
	_toggle.custom_minimum_size = Vector2(54, 54)
	_toggle.set_script(preload("res://scripts/inventory_icon.gd"))
	_toggle.tooltip_text = "Ekwipunek"
	_toggle.pressed.connect(_toggle_panel)
	overlay.add_child(_toggle)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(320, 280)
	_panel.add_theme_stylebox_override("panel", _style(PANEL_BG, ACCENT, 2, 12))
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	_panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "EKWIPUNEK"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", ACCENT)
	header.add_child(title)
	var close := Button.new()
	close.text = "×"
	close.custom_minimum_size = Vector2(42, 38)
	close.pressed.connect(_close_panel)
	header.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)
	_collectibles_tab = Button.new()
	_collectibles_tab.text = "Collectibles"
	_collectibles_tab.toggle_mode = true
	_collectibles_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collectibles_tab.pressed.connect(_select_category.bind(ItemDefinition.Category.COLLECTIBLE))
	tabs.add_child(_collectibles_tab)
	_gameplay_tab = Button.new()
	_gameplay_tab.text = "Gameplay Items"
	_gameplay_tab.toggle_mode = true
	_gameplay_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gameplay_tab.pressed.connect(_select_category.bind(ItemDefinition.Category.GAMEPLAY))
	tabs.add_child(_gameplay_tab)

	var scroller := ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroller.add_child(_grid)
	_empty = Label.new()
	_empty.text = "Brak przedmiotów"
	_empty.custom_minimum_size = Vector2(0, 160)
	_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.add_theme_font_size_override("font_size", 18)
	_empty.add_theme_color_override("font_color", Color(0.76, 0.77, 0.78))
	_grid.add_child(_empty)

	var details := PanelContainer.new()
	details.custom_minimum_size = Vector2(0, 116)
	details.add_theme_stylebox_override("panel", _style(Color(0.13, 0.15, 0.17, 1.0), Color(0.35, 0.38, 0.40), 1, 8))
	content.add_child(details)
	var detail_layout := VBoxContainer.new()
	detail_layout.add_theme_constant_override("separation", 6)
	details.add_child(detail_layout)
	_details_title = Label.new()
	_details_title.text = "Wybierz przedmiot"
	_details_title.add_theme_font_size_override("font_size", 18)
	_details_title.add_theme_color_override("font_color", ACCENT)
	detail_layout.add_child(_details_title)
	_details_description = Label.new()
	_details_description.text = ""
	_details_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_layout.add_child(_details_description)

func _resize_panel() -> void:
	if not is_instance_valid(_panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := Vector2(minf(680.0, viewport_size.x - 32.0), minf(500.0, viewport_size.y - 32.0))
	_panel.offset_left = -panel_size.x * 0.5
	_panel.offset_top = -panel_size.y * 0.5
	_panel.offset_right = panel_size.x * 0.5
	_panel.offset_bottom = panel_size.y * 0.5
	_grid.columns = maxi(1, int((_panel.size.x - 64.0) / 122.0))

func _toggle_panel() -> void:
	if _panel.visible:
		_close_panel()
	else:
		_open_panel()

func is_open() -> bool:
	return is_instance_valid(_panel) and _panel.visible

func close_from_manager() -> void:
	if is_open():
		_close_panel()

func _open_panel() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(_player) or DialogueManager.is_active():
		return
	_panel.visible = true
	if _player.has_method("acquire_movement_lock"):
		_player.acquire_movement_lock(&"inventory")
		_lock_held = true
	elif _player.has_method("set_movement_locked"):
		_player.set_movement_locked(true)
		_lock_held = true

func _close_panel() -> void:
	_panel.visible = false
	_release_lock()

func _release_lock() -> void:
	if _lock_held and is_instance_valid(_player):
		if _player.has_method("release_movement_lock"):
			_player.release_movement_lock(&"inventory")
		elif _player.has_method("set_movement_locked"):
			_player.set_movement_locked(false)
	_lock_held = false
	_player = null

func _select_category(category: ItemDefinition.Category) -> void:
	_selected_category = category
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(_grid):
		return
	for child in _grid.get_children():
		_grid.remove_child(child)
		if child != _empty:
			child.queue_free()
	_collectibles_tab.button_pressed = _selected_category == ItemDefinition.Category.COLLECTIBLE
	_gameplay_tab.button_pressed = _selected_category == ItemDefinition.Category.GAMEPLAY
	var entries := InventoryManager.get_items(_selected_category)
	var selection_exists := false
	for entry in entries:
		if entry.definition.id == _selected_item_id:
			selection_exists = true
	if not selection_exists:
		_selected_item_id = entries[0].definition.id if not entries.is_empty() else &""
	_empty.visible = entries.is_empty()
	_grid.add_child(_empty)
	for entry in entries:
		_grid.add_child(_make_slot(entry.definition, entry.amount))
	_update_details()

func _make_slot(definition: InventoryItem, amount: int) -> Control:
	var slot := Button.new()
	slot.pressed.connect(_select_item.bind(definition.id))
	slot.custom_minimum_size = Vector2(112, 120)
	var border := ACCENT if definition.id == _selected_item_id else Color(0.35, 0.38, 0.40)
	var width := 2 if definition.id == _selected_item_id else 1
	slot.add_theme_stylebox_override("normal", _style(SLOT_BG, border, width, 8))
	slot.add_theme_stylebox_override("hover", _style(Color(0.2, 0.22, 0.24), ACCENT, 2, 8))
	slot.add_theme_stylebox_override("pressed", _style(Color(0.23, 0.22, 0.18), ACCENT, 2, 8))
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(100, 108)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(stack)
	var icon := TextureRect.new()
	icon.texture = definition.icon
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 10
	icon.offset_top = 8
	icon.offset_right = -10
	icon.offset_bottom = -34
	stack.add_child(icon)
	var name_label := Label.new()
	name_label.text = definition.display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_label.offset_left = 3
	name_label.offset_top = -28
	name_label.offset_right = -3
	name_label.offset_bottom = -3
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.tooltip_text = definition.description
	stack.add_child(name_label)
	var count := Label.new()
	count.text = str(amount)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	count.position = Vector2(-26, 2)
	count.custom_minimum_size = Vector2(22, 22)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.add_theme_color_override("font_color", ACCENT)
	count.add_theme_color_override("font_shadow_color", Color.BLACK)
	count.add_theme_constant_override("shadow_offset_x", 1)
	count.add_theme_constant_override("shadow_offset_y", 1)
	stack.add_child(count)
	return slot

func _select_item(item_id: StringName) -> void:
	_selected_item_id = item_id
	_refresh()

func _update_details() -> void:
	var definition := InventoryManager.get_definition(_selected_item_id)
	if definition == null or not InventoryManager.has_item(_selected_item_id):
		_details_title.text = "Wybierz przedmiot"
		_details_description.text = ""
		return
	_details_title.text = definition.display_name
	_details_description.text = definition.description

func _on_item_added(item_id: StringName, _amount: int) -> void:
	var definition := InventoryManager.get_definition(item_id)
	if definition != null and (definition.categories & ItemDefinition.Category.COLLECTIBLE) != 0:
		_selected_category = ItemDefinition.Category.COLLECTIBLE
		_selected_item_id = item_id
		_refresh()

func _style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box
