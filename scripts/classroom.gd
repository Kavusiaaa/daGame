extends Node2D

const DoorScene: PackedScene = preload("res://door.tscn")

@onready var _spawn: Marker2D = $RoomSpawn

func _ready() -> void:
	MusicManager.play_game_music()
	var room_id := RoomManager.active_room_id
	var config := RoomManager.get_room(room_id)
	if config.is_empty():
		push_warning("Unknown classroom ID '%s'; loading classroom_01." % room_id)
		room_id = &"classroom_01"
		RoomManager.select_room(room_id)
		config = RoomManager.get_room(room_id)
	_spawn.position = RoomManager.vector2_from(config.get("spawn", [0, 150]), Vector2(0, 150))
	_build_instances(config.get("furniture", []), false)
	_build_instances(config.get("npcs", []), true)
	_build_exit(config)

func _build_instances(entries: Array, is_npc: bool) -> void:
	for entry_variant in entries:
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		var packed := load(str(entry.get("scene", ""))) as PackedScene
		if packed == null:
			push_warning("Missing room resource: %s" % entry.get("scene", ""))
			continue
		var instance := packed.instantiate() as Node2D
		instance.name = str(entry.get("name", "RoomObject"))
		instance.position = RoomManager.vector2_from(entry.get("position", [0, 0]))
		instance.rotation = float(entry.get("rotation", 0.0))
		instance.scale = RoomManager.vector2_from(entry.get("scale", [1, 1]), Vector2.ONE)
		if is_npc:
			instance.set("npc_name", str(entry.get("name", "Nauczyciel")))
		add_child(instance)

func _build_exit(config: Dictionary) -> void:
	var exit_door := DoorScene.instantiate() as Node2D
	exit_door.name = "ExitDoor"
	exit_door.position = RoomManager.vector2_from(config.get("exit_position", [240, 0]))
	exit_door.set("target_scene", "res://school.tscn")
	exit_door.set("target_spawn_point", NodePath(str(config.get("return_spawn", "RoomReturn01"))))
	exit_door.set("door_name", "Wyjście z sali")
	exit_door.set("interaction_text", "E - Wyjdź")
	add_child(exit_door)
