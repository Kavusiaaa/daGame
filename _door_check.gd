extends SceneTree

func _initialize() -> void:
	call_deferred("_run_check")

func _press_interact(door: Node2D) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	door._input(event)
	await physics_frame
	event = event.duplicate() as InputEventKey
	event.pressed = false
	door._input(event)
	await physics_frame

func _enter_from(door: Node2D, expected_room_id: StringName) -> Node2D:
	var player := get_first_node_in_group("player") as Node2D
	player.global_position = door.global_position
	door._process(0.0)
	assert(door.player_near == player, "Door proximity fallback did not find the player.")
	await _press_interact(door)
	await create_timer(0.9).timeout
	assert(current_scene != null and current_scene.scene_file_path == "res://classroom.tscn", "Door did not load classroom.tscn.")
	assert(root.get_node("RoomManager").active_room_id == expected_room_id, "Door did not pass the selected room ID.")
	var room_player := get_first_node_in_group("player") as Node2D
	var spawn := current_scene.get_node("RoomSpawn") as Node2D
	assert(room_player.global_position.distance_to(spawn.global_position) < 1.0, "Player did not use the configured classroom spawn.")
	assert(current_scene.get_node_or_null("ExitDoor") != null, "Classroom exit door was not generated.")
	return room_player

func _leave_to_school(room_id: StringName) -> void:
	var exit_door := current_scene.get_node("ExitDoor") as Node2D
	var player := get_first_node_in_group("player") as Node2D
	player.global_position = exit_door.global_position
	exit_door._process(0.0)
	assert(exit_door.player_near == player, "Classroom exit proximity did not find the player.")
	await _press_interact(exit_door)
	await create_timer(0.9).timeout
	assert(current_scene != null and current_scene.scene_file_path == "res://school.tscn", "Classroom exit did not return to school.tscn.")
	var return_marker := current_scene.get_node("RoomReturn%02d" % (1 if room_id == &"classroom_01" else 2)) as Node2D
	player = get_first_node_in_group("player") as Node2D
	assert(player.global_position.distance_to(return_marker.global_position) < 1.0, "Player did not use the room return marker.")

func _run_check() -> void:
	await process_frame
	var load_error := change_scene_to_file("res://school.tscn")
	assert(load_error == OK, "Could not set school.tscn as current_scene.")
	await scene_changed
	var school := current_scene
	var door_1 := school.get_node("Door_01") as Node2D
	await _enter_from(door_1, &"classroom_01")
	assert(current_scene.get_node_or_null("Stół nauczyciela") != null, "Room 1 furniture was not generated.")
	await _leave_to_school(&"classroom_01")

	school = current_scene
	var door_2 := school.get_node("Door") as Node2D
	await _enter_from(door_2, &"classroom_02")
	assert(current_scene.get_node_or_null("Stół 1") != null, "Room 2 furniture was not generated.")
	assert(current_scene.get_node_or_null("Stół 2") != null, "Room 2 furniture was not generated.")
	await _leave_to_school(&"classroom_02")

	print("DOOR INTERACTION AND DYNAMIC ROOM TRANSITIONS OK")
	quit(0)
