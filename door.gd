extends Node2D

const CLASSROOM_SCENE := "res://classroom.tscn"

@export var target_scene: String = ""
@export var target_room_id: StringName = &""
@export var target_spawn_point: NodePath
@export var door_name: String = "Sala lekcyjna"
@export var locked: bool = false
@export var interaction_text: String = "E - Wejdź"
@export_range(32.0, 192.0, 4.0) var interaction_distance: float = 112.0
@export var teleport_point: NodePath = NodePath("TeleportPoint")

var player_near: Node2D
@onready var press_e: Label = $PressE

func _ready() -> void:
	if target_spawn_point.is_empty():
		target_spawn_point = teleport_point
	press_e.visible = false
	press_e.text = "Zamknięte" if locked else interaction_text

# Read E in _input so unrelated UI/unhandled-input listeners cannot swallow door use.
func _process(_delta: float) -> void:
	# Keep interaction available at wall-mounted doors even when collision geometry
	# prevents the player's body from entering the trigger Area2D.
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= interaction_distance:
		player_near = player
		press_e.visible = true
	elif is_instance_valid(player_near):
		player_near = null
		press_e.visible = false

func _input(event: InputEvent) -> void:
	if event.is_echo() or locked or DialogueManager.is_active():
		return
	if not is_instance_valid(player_near):
		return
	var interact_pressed := event.is_action_pressed("interact")
	if event is InputEventKey:
		interact_pressed = interact_pressed or (
			event.pressed and not event.is_echo()
			and (event.keycode == KEY_E or event.physical_keycode == KEY_E)
		)
	if interact_pressed:
		teleport_player()
		get_viewport().set_input_as_handled()

func teleport_player() -> void:
	if locked or not is_instance_valid(player_near) or DialogueManager.is_active():
		return

	var destination_scene := target_scene.strip_edges()
	var destination := Vector2.ZERO
	if destination_scene.is_empty():
		if not target_room_id.is_empty():
			destination_scene = CLASSROOM_SCENE
		else:
			var target := get_node_or_null(target_spawn_point) as Node2D
			if target == null:
				push_warning("Door '%s' has no valid target_spawn_point." % door_name)
				return
			destination = target.global_position

	if not destination_scene.is_empty():
		if not ResourceLoader.exists(destination_scene):
			push_error("Door '%s' targets a missing scene: %s" % [door_name, destination_scene])
			return
		if not target_room_id.is_empty() and RoomManager.get_room(target_room_id).is_empty():
			push_error("Door '%s' targets an unknown room ID: %s" % [door_name, target_room_id])
			return

	TransitionManager.transition_player(
		player_near,
		destination,
		destination_scene,
		target_spawn_point,
		target_room_id
	)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_near = body
		press_e.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_near:
		player_near = null
		press_e.visible = false
