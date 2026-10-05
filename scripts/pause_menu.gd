extends CanvasLayer

const SAVE_PATH := "user://savegame.json"
const ACTIONS := {"move_up":"Góra", "move_down":"Dół", "move_left":"Lewo", "move_right":"Prawo", "interact":"Interakcja", "inventory":"Ekwipunek", "pause":"Pauza"}
var _root: Control
var _stack: Control
var _confirming := false
var _waiting_action: StringName = &""
var _toast: Label
var _from_gameplay := true

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.is_in_group("player"):
		_from_gameplay = true

func _unhandled_input(event: InputEvent) -> void:
	if _waiting_action != &"":
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			get_viewport().set_input_as_handled()
			if GameSettings.set_keybind(_waiting_action, event):
				_waiting_action = &""
				_show_options()
		return
	if not event.is_action_pressed("pause") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if not get_tree().paused and not _from_gameplay:
		_root.visible = false
		get_tree().change_scene_to_file("res://main_menu.tscn")
		return
	if _confirming:
		_confirming = false
		_show_main()
		return
	if get_tree().paused:
		if DialogueManager.is_active():
			get_tree().paused = false
			_root.visible = false
		else:
			_resume()
	else:
		_open()

func _open() -> void:
	if InventoryUI.is_open():
		InventoryUI.close_from_manager()
	get_tree().paused = true
	_root.visible = true
	_show_main()

func _resume() -> void:
	_root.visible = false
	get_tree().paused = false

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	add_child(_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.025, 0.035, 0.78)
	_root.add_child(shade)
	_stack = Control.new()
	_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_stack)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_toast.offset_top = -54
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 20)
	_root.add_child(_toast)

func _clear() -> void:
	for child in _stack.get_children():
		child.queue_free()

func _panel(title_text: String) -> VBoxContainer:
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stack.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.15, 0.98)
	style.border_color = Color(0.82, 0.68, 0.42)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, minf(560.0, get_viewport().get_visible_rect().size.y - 64.0))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.91, 0.78, 0.54))
	column.add_child(title)
	return column

func _button(parent: VBoxContainer, title: String, callback: Callable, disabled := false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(360, 44)
	button.disabled = disabled
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.19, 0.22, 0.25) if state == "normal" else Color(0.30, 0.27, 0.20) if state == "hover" else Color(0.12, 0.14, 0.16) if state == "pressed" else Color(0.12, 0.12, 0.13)
		box.set_corner_radius_all(6)
		button.add_theme_stylebox_override(state, box)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _show_main() -> void:
	_confirming = false
	var column := _panel("GRA ZATRZYMANA")
	_button(column, "WZNÓW GRĘ", _resume)
	_button(column, "ZAPISZ GRĘ", _save_game)
	_button(column, "OPCJE", _show_options)
	_button(column, "DOSTOSOWANIE POSTACI", _show_customization)
	_button(column, "WYJDŹ DO MENU", _show_exit_confirmation)

func _show_options() -> void:
	var column := _panel("OPCJE")
	_add_slider(column, "Muzyka", "Music")
	_add_slider(column, "SFX", "SFX")
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.1
	sensitivity.max_value = 3.0
	sensitivity.step = 0.1
	sensitivity.value = GameSettings.get_mouse_sensitivity()
	sensitivity.value_changed.connect(GameSettings.set_mouse_sensitivity)
	column.add_child(_labelled_control(column, "Czułość myszy", sensitivity))
	for action in ACTIONS:
		var row := HBoxContainer.new()
		var action_label := Label.new()
		action_label.text = ACTIONS[action]
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(action_label)
		var bind := Button.new()
		bind.text = "%s — %s" % [ACTIONS[action], _key_name(action)]
		bind.custom_minimum_size = Vector2(240, 44)
		bind.pressed.connect(func():
			_waiting_action = StringName(action)
			_toast.text = "Naciśnij nowy klawisz dla: %s" % ACTIONS[action]
		)
		row.add_child(bind)
		column.add_child(row)
	_button(column, "PRZYWRÓĆ DOMYŚLNE", _reset_settings)
	_button(column, "WRÓĆ", _options_back)

func open_title_options() -> void:
	_from_gameplay = false
	_root.visible = true
	_show_options()

func _options_back() -> void:
	if _from_gameplay:
		_show_main()
	else:
		_root.visible = false
		get_tree().change_scene_to_file("res://main_menu.tscn")

func _add_slider(parent: VBoxContainer, label: String, bus: String) -> void:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = GameSettings.get_audio_linear(bus)
	slider.value_changed.connect(GameSettings.set_audio.bind(bus))
	parent.add_child(_labelled_control(parent, label, slider))

func _labelled_control(_parent: VBoxContainer, label_text: String, control: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	box.add_child(control)
	return box

func _key_name(action: String) -> String:
	var key := GameSettings.get_action_event(StringName(action))
	return key.as_text() if key != null else "—"

func _reset_settings() -> void:
	GameSettings.reset()
	_show_options()

func _save_game() -> void:
	var data := {"inventory": InventoryManager.to_save_data(), "saved_at": Time.get_datetime_string_from_system()}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_toast.text = "Nie udało się zapisać gry."
		return
	file.store_string(JSON.stringify(data, "\t"))
	_toast.text = "Gra została zapisana."

func _show_customization() -> void:
	var column := _panel("DOSTOSOWANIE POSTACI")
	for option in ["Włosy — WKRÓTCE", "Ubrania — WKRÓTCE", "Kolor — WKRÓTCE", "Dodatki — WKRÓTCE"]:
		_button(column, option, func(): pass, true)
	_button(column, "WRÓĆ", _show_main)

func _show_exit_confirmation() -> void:
	_confirming = true
	var column := _panel("Czy na pewno chcesz wyjść do menu?")
	_button(column, "TAK", _exit_to_menu)
	_button(column, "NIE", _show_main)

func _exit_to_menu() -> void:
	_root.visible = false
	get_tree().paused = false
	_from_gameplay = true
	get_tree().change_scene_to_file("res://main_menu.tscn")
