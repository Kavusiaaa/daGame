extends SceneTree

func _initialize() -> void:
	call_deferred("_run_check")

func _run_check() -> void:
	var school: Node = load("res://school.tscn").instantiate()
	root.add_child(school)
	await physics_frame
	var player: CharacterBody2D = school.get_node("Player/Player")
	for door_name in ["Door_01", "Door"]:
		var door: Node2D = school.get_node(door_name)
		player.global_position = door.global_position
		await physics_frame
		await physics_frame
		assert(door.player_near == player)
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		event.pressed = true
		Input.parse_input_event(event)
		await physics_frame
		var release_event := event.duplicate() as InputEventKey
		release_event.pressed = false
		Input.parse_input_event(release_event)
		await create_timer(0.75).timeout
		var destination: Node2D = door.get_node(door.target_spawn_point)
		print(door_name, " target: ", player.global_position, " expected: ", destination.global_position)
		assert(player.global_position.distance_to(destination.global_position) < 1.0)
		assert(not player.movement_locked)
	school.get_node("AudioStreamPlayer2D").stop()
	school.queue_free()
	await process_frame
	print("BOTH DOOR DIRECTIONS OK")
	quit(0)
