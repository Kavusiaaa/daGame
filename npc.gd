extends Node2D

@export var npc_name: String = "Woźny"
@export var dialogue: Array[Dictionary] = [
	{"speaker": "Woźny", "text": "Ej, ty!"},
	{"speaker": "Gracz", "text": "Ja?"},
	{"speaker": "Woźny", "text": "Piwnica jest zamknięta. Lepiej tam nie schodź."}
]
@export var dialogue_id: StringName = &""
@export var completion_reward_id: StringName = &""
@export var completion_reward_item_id: StringName = &""

var player_near: Node2D
@onready var prompt: Label = $Chat_detection_area/Label

func _ready() -> void:
	prompt.text = "E - Rozmawiaj"
	prompt.visible = false
	DialogueManager.dialogue_completed.connect(_on_dialogue_completed)

func _process(_delta: float) -> void:
	if is_instance_valid(player_near) and Input.is_action_just_pressed("interact") and not DialogueManager.is_active():
		DialogueManager.start_dialogue(npc_name, dialogue, player_near, dialogue_id)

func _on_dialogue_completed(completed_dialogue_id: StringName, _player: Node) -> void:
	if completed_dialogue_id != dialogue_id or completion_reward_id.is_empty() or completion_reward_item_id.is_empty():
		return
	InventoryManager.grant_reward_once(completion_reward_id, completion_reward_item_id)

func _on_chat_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = body
		prompt.visible = true

func _on_chat_detection_area_body_exited(body: Node2D) -> void:
	if body == player_near:
		DialogueManager.cancel_dialogue(body)
		player_near = null
		prompt.visible = false
