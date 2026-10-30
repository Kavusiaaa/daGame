extends Area2D

@export var roof_layer_path: NodePath
@export_range(0.0, 1.0, 0.05) var hidden_alpha: float = 0.15
@export_range(0.05, 2.0, 0.05) var fade_duration: float = 0.35

@onready var roof_layer: CanvasItem = get_node_or_null(roof_layer_path) as CanvasItem
var _fade_tween: Tween

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fade_to(hidden_alpha)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fade_to(1.0)

func _fade_to(alpha: float) -> void:
	if not is_instance_valid(roof_layer):
		return
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(roof_layer, "modulate:a", alpha, fade_duration)
