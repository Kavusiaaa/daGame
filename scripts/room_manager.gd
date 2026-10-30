extends Node
const ROOMS_FILE := "res://data/rooms.json"
var active_room_id: StringName = &""
var _rooms: Dictionary = {}
func _ready() -> void:
 var file := FileAccess.open(ROOMS_FILE, FileAccess.READ)
 if file == null:
  push_error("Could not open room configuration: %s" % ROOMS_FILE)
  return
 var parsed: Variant = JSON.parse_string(file.get_as_text())
 if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("rooms")) != TYPE_DICTIONARY:
  push_error("Room configuration must contain a rooms dictionary.")
  return
 _rooms = parsed["rooms"]
func select_room(room_id: StringName) -> void:
 active_room_id = room_id
func get_room(room_id: StringName = &"") -> Dictionary:
 var key := room_id if not room_id.is_empty() else active_room_id
 return _rooms.get(String(key), {}) as Dictionary
func vector2_from(data: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
 if data is Array and data.size() >= 2:
  return Vector2(float(data[0]), float(data[1]))
 return fallback
