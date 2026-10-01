extends Node2D

@export var npc_name: String = "Woźny"
@export var dialogue: Array[Dictionary] = [
	{"speaker": "Woźny", "text": "Ej, ty!"},
	{"speaker": "Gracz", "text": "Ja?"},
	{"speaker": "Woźny", "text": "Piwnica jest zamknięta. Lepiej tam nie schodź."}
]

var player_near: Node2D
@onready var prompt: Label = $Chat_detection_area/Label

func _ready() -> void:
	prompt.text = "E - Rozmawiaj"
	prompt.visible = false

func _process(_delta: float) -> void:
	if is_instance_valid(player_near) and Input.is_action_just_pressed("interact") and not DialogueManager.is_active():
		DialogueManager.start_dialogue(npc_name, dialogue, player_near)

func _on_chat_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = body
		prompt.visible = true

func _on_chat_detection_area_body_exited(body: Node2D) -> void:
	if body == player_near:
		DialogueManager.cancel_dialogue(body)
		player_near = null
		prompt.visible = false
