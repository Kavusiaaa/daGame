extends Button

func _draw() -> void:
	var center := size * 0.5
	var body := Rect2(center.x - 13, center.y - 7, 26, 22)
	draw_rect(body, Color(0.82, 0.68, 0.42), true)
	draw_rect(Rect2(center.x - 9, center.y - 11, 18, 9), Color(0.82, 0.68, 0.42), false, 3.0)
	draw_line(Vector2(center.x, center.y - 6), Vector2(center.x, center.y + 14), Color(0.18, 0.16, 0.13), 2.0)
