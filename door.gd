extends Node2D

@export var teleport_point : NodePath

var player_near = null
@onready var press_e = $PressE

func _ready():
	press_e.visible = false

func _process(delta):
	if player_near and Input.is_action_just_pressed("interact"):
		teleport_player()

func teleport_player():
	var target = get_node(teleport_point)
	if not player_near:
		return
		
	if "velocity" in player_near:
		player_near.velocity = Vector2.ZERO
		
	player_near.global_position = target.global_position


func _on_area_2d_body_entered(body):
	print("ENTER:", body, " parent:", body.get_parent())
	if body.name == "Player":  # albo: body.is_in_group("player")
		player_near = body
		press_e.visible = true
	


func _on_area_2d_body_exited(body):
	print("EXIT:", body, " parent:", body.get_parent())
	if body == player_near:
		player_near = null
		press_e.visible = false
