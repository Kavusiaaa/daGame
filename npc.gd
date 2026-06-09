extends Node2D
const speed = 30
var current_state = IDLE

var dir = Vector2.RIGHT
var start_pos

var is_roaming = true
var is_chatting = false

var player
var player_in_chat_zone = false
enum {
	IDLE,
	NEW_DIR,
	MOVE
}

func _ready():
	randomize()
	start_pos = position
func _process(delta):
	if current_state == 0 or current_state == 1:
		pass
		#$Stickman.play("idle") - animacja idle #
	elif current_state == 2 and !is_chatting:
		if dir.x == -1:
			pass
			#$Stickman.play("walk_w") - do dokonczenia system 
	
