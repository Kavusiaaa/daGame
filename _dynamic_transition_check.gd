extends SceneTree
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 await process_frame
 var room_manager: Node = root.get_node("RoomManager")
 var music_manager: Node = root.get_node("MusicManager")
 music_manager.call("play_game_music")
 var music := music_manager.get_node("BackgroundMusic") as AudioStreamPlayer
 var track := music.stream
 room_manager.call("select_room", &"classroom_02")
 var room: Node = load("res://classroom.tscn").instantiate()
 root.add_child(room)
 await process_frame
 assert(room.get_node_or_null("Stół 1") != null)
 assert(room.get_node_or_null("Stół 2") != null)
 assert(room.get_node_or_null("ExitDoor") != null)
 assert(room.get_node_or_null("Player") != null)
 print("ROOM2_GENERATION_OK children=", room.get_child_count())
 room.queue_free()
 await process_frame
 var school: Node = load("res://school.tscn").instantiate()
 root.add_child(school)
 await process_frame
 assert(music.stream == track and music.playing)
 print("MUSIC_AUTOLOAD_CONTINUES_OK")
 quit()
