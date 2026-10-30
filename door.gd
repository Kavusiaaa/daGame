extends Node2D

@export var target_scene: String = ""
@export var target_room_id: StringName = &""
@export var target_spawn_point: NodePath
@export var door_name: String = "Sala lekcyjna"
@export var locked: bool = false
@export var interaction_text: String = "E - Wejdź"
# Legacy property retained for the existing school scene overrides.
@export var teleport_point: NodePath = NodePath("TeleportPoint")

var player_near: Node2D
@onready var press_e: Label = $PressE

func _ready() -> void:
	if target_spawn_point.is_empty():
		target_spawn_point = teleport_point
	press_e.visible = false
	press_e.text = "Zamknięte" if locked else interaction_text

func _unhandled_input(event: InputEvent) -> void:
	if not player_near or locked or DialogueManager.is_active():
		return
	if event.is_action_pressed("interact"):
		teleport_player()
		get_viewport().set_input_as_handled()

func teleport_player() -> void:
	if not is_instance_valid(player_near):
		return
	var destination := Vector2.ZERO
	if target_scene.is_empty():
		var target := get_node_or_null(target_spawn_point) as Node2D
		if target == null:
			push_warning("Door '%s' has no valid target_spawn_point." % door_name)
			return
		destination = target.global_position
	var destination_scene := target_scene
	if destination_scene.is_empty() and not target_room_id.is_empty():
		destination_scene = "res://classroom.tscn"
	TransitionManager.transition_player(player_near, destination, destination_scene, target_spawn_point, target_room_id)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_near = body
		press_e.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_near:
		player_near = null
		press_e.visible = false
