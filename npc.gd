extends Node2D

@export var npc_name: String = "Nauczyciel"
@export var dialogue: Array[Dictionary] = [
	{"speaker": "Woźny", "text": "Ej, ty!"},
	{"speaker": "Gracz", "text": "Ja?"},
	{"speaker": "Woźny", "text": "Piwnica jest zamknięta. Lepiej tam nie schodź."}
]
@export var dialogue_id: StringName = &""
@export var return_dialogue: Array[Dictionary] = [{"speaker": "WoĹşny", "text": "Witaj ponownie."}]
@export var completion_reward_id: StringName = &""
@export var completion_reward_item_id: StringName = &""
@export var completion_reward_coins: int = 0
@export var repeatable_dialogue := true
@export var can_interact := true
@export var dialogue_completed := false
@export var reward_given := false
var has_met_npc := false

var player_near: Node2D
@onready var prompt: Label = $Chat_detection_area/Label

func _ready() -> void:
	prompt.text = "E - Rozmawiaj"
	prompt.visible = false
	DialogueManager.dialogue_completed.connect(_on_dialogue_completed)

func _process(_delta: float) -> void:
	if can_interact and is_instance_valid(player_near) and Input.is_action_just_pressed("interact") and DialogueManager.can_start_dialogue():
		if dialogue_completed and not repeatable_dialogue:
			return
		var lines: Array[Dictionary] = dialogue if not has_met_npc else return_dialogue.duplicate(true)
		# Treść powrotna nie może nadpisać imienia NPC; placeholder Woźny jest zastępowany nazwą z Inspectora.
		if has_met_npc:
			for line in lines:
				if str(line.get("speaker", "")) == "Woźny":
					line["speaker"] = npc_name
		DialogueManager.start_dialogue(npc_name, lines, player_near, dialogue_id)

func _on_dialogue_completed(completed_dialogue_id: StringName, _player: Node) -> void:
	if completed_dialogue_id != dialogue_id:
		return
	dialogue_completed = true
	has_met_npc = true
	if dialogue_id == &"teacher_note_dialogue":
		AchievementManager.unlock_achievement("met_the_teacher")
	if reward_given:
		return
	if not completion_reward_id.is_empty() and not completion_reward_item_id.is_empty():
		InventoryManager.grant_reward_once(StringName("%s_item" % completion_reward_id), completion_reward_item_id)
	if not completion_reward_id.is_empty() and completion_reward_coins > 0:
		InventoryManager.grant_coins_once(StringName("%s_coins" % completion_reward_id), completion_reward_coins)
	reward_given = not completion_reward_id.is_empty() and (not completion_reward_item_id.is_empty() or completion_reward_coins > 0)

func _on_chat_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = body
		prompt.visible = true

func _on_chat_detection_area_body_exited(body: Node2D) -> void:
	if body == player_near:
		DialogueManager.cancel_dialogue(body)
		player_near = null
		prompt.visible = false
