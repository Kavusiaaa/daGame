extends CanvasLayer

var _busy := false
var _cover: ColorRect

func _ready() -> void:
	layer = 100
	_cover = ColorRect.new()
	_cover.color = Color.BLACK
	_cover.modulate.a = 0.0
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cover)

func transition_player(player: Node2D, destination: Vector2, scene_path: String = "", spawn_path: NodePath = NodePath(), room_id: StringName = &"") -> void:
	if _busy or not is_instance_valid(player):
		return
	_busy = true
	_set_player_locked(player, true)
	await _fade_to(1.0, 0.22)
	await get_tree().create_timer(0.12).timeout
	if not scene_path.is_empty():
		RoomManager.select_room(room_id)
		var error := get_tree().change_scene_to_file(scene_path)
		if error != OK:
			RoomManager.select_room(&"")
			push_error("Could not load door target scene: %s" % scene_path)
			await _fade_to(0.0, 0.22)
			_set_player_locked(player, false)
			_busy = false
			return
		await get_tree().scene_changed
		player = get_tree().get_first_node_in_group("player") as Node2D
		var spawn := _find_spawn(spawn_path)
		if spawn != null:
			destination = spawn.global_position
		else:
			push_error("Target scene '%s' has no spawn node at '%s'." % [scene_path, spawn_path])
			RoomManager.select_room(&"")
			await _fade_to(0.0, 0.22)
			_set_player_locked(player, false)
			_busy = false
			return
	if is_instance_valid(player):
		player.global_position = destination
		_set_player_locked(player, true)
	await get_tree().process_frame
	await _fade_to(0.0, 0.22)
	_set_player_locked(player, false)
	_busy = false

func _set_player_locked(player: Node, value: bool) -> void:
	if not is_instance_valid(player):
		return
	if player.has_method("acquire_movement_lock"):
		if value:
			player.acquire_movement_lock(&"transition")
		else:
			player.release_movement_lock(&"transition")
	elif player.has_method("set_movement_locked"):
		player.set_movement_locked(value)

func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_cover, "modulate:a", alpha, duration)
	await tween.finished

func _find_spawn(spawn_path: NodePath) -> Node2D:
	var scene := get_tree().current_scene
	if is_instance_valid(scene):
		var scene_spawn := scene.get_node_or_null(spawn_path) as Node2D
		if scene_spawn != null:
			return scene_spawn
	return get_tree().root.find_child(str(spawn_path), true, false) as Node2D
