extends Area2D

@export var DachDziedziniec: Node2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if DachDziedziniec:
			DachDziedziniec.visible = false

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if DachDziedziniec:
			DachDziedziniec.visible = true
