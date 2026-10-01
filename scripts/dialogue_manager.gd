extends CanvasLayer

var _active := false
var _lines: Array[Dictionary] = []
var _index := 0
var _visible_characters := 0
var _character_accumulator := 0.0
var _player: Node
var _speaker: Label
var _body: Label
var _hint: Label
var _prompt_panel: PanelContainer

func _ready() -> void:
	layer = 90
	_build_ui()

func _process(delta: float) -> void:
	if _active and _visible_characters < _body.text.length():
		_character_accumulator += 48.0 * delta
		var characters_to_reveal := int(_character_accumulator)
		if characters_to_reveal > 0:
			_character_accumulator -= characters_to_reveal
			_visible_characters = mini(_visible_characters + characters_to_reveal, _body.text.length())
			_body.visible_characters = _visible_characters
	if _active and Input.is_action_just_pressed("interact"):
		_advance()

func is_active() -> bool:
	return _active

func start_dialogue(default_speaker: String, lines: Array[Dictionary], player: Node) -> void:
	if _active or lines.is_empty() or not is_instance_valid(player):
		return
	_lines = lines
	_index = 0
	_player = player
	_active = true
	if player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
	_show_line(default_speaker)

func cancel_dialogue(player: Node) -> void:
	if _active and player == _player:
		_end_dialogue()

func _advance() -> void:
	if _visible_characters < _body.text.length():
		_visible_characters = _body.text.length()
		_character_accumulator = 0.0
		_body.visible_characters = _visible_characters
		return
	_index += 1
	if _index >= _lines.size():
		_end_dialogue()
	else:
		_show_line("")

func _show_line(default_speaker: String) -> void:
	var line: Dictionary = _lines[_index]
	_speaker.text = str(line.get("speaker", default_speaker))
	_body.text = str(line.get("text", ""))
	_visible_characters = 0
	_character_accumulator = 0.0
	_body.visible_characters = 0
	_hint.text = "E - dalej"
	_prompt_panel.visible = true

func _end_dialogue() -> void:
	_active = false
	_prompt_panel.visible = false
	_lines.clear()
	if is_instance_valid(_player) and _player.has_method("set_movement_locked"):
		_player.set_movement_locked(false)
	_player = null

func _build_ui() -> void:
	_prompt_panel = PanelContainer.new()
	_prompt_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_panel.offset_left = 48.0
	_prompt_panel.offset_right = -48.0
	_prompt_panel.offset_top = -166.0
	_prompt_panel.offset_bottom = -24.0
	_prompt_panel.add_theme_stylebox_override("panel", _panel_style())
	_prompt_panel.visible = false
	add_child(_prompt_panel)
	var layout := VBoxContainer.new()
	_prompt_panel.add_child(layout)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 22)
	layout.add_child(_speaker)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 18)
	layout.add_child(_body)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 14)
	layout.add_child(_hint)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.04, 0.94)
	style.border_color = Color(0.8, 0.72, 0.53, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 10.0
	return style
