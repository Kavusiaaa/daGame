extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	var menu = load("res://main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var pause_event = InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	root.get_node("PauseMenu")._unhandled_input(pause_event)
	print("TITLE_ESC paused=", paused, " overlay=", root.get_node("PauseMenu")._root.visible)
	var options = menu.get_node("VBoxContainer/Opcje")
	print("OPTIONS_HITBOX ", options.get_global_rect(), " size=", options.size, " texture=", options.texture_normal.get_size())
	_click(options)
	await create_timer(1.0).timeout
	print("OPTIONS_CLICK scene=", current_scene.scene_file_path)
	var new_menu = load("res://main_menu.tscn").instantiate()
	root.add_child(new_menu)
	current_scene.queue_free()
	current_scene = new_menu
	await process_frame
	var start = new_menu.get_node("VBoxContainer/Start")
	print("START_HITBOX ", start.get_global_rect(), " size=", start.size, " texture=", start.texture_normal.get_size())
	_click(start)
	await create_timer(3.0).timeout
	print("START_CLICK scene=", current_scene.scene_file_path, " paused=", paused)
	quit()
func _click(button: Control):
	var pos = button.get_global_rect().get_center()
	var event = InputEventMouseButton.new()
	event.position = pos
	event.global_position = pos
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
