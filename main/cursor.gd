extends Node2D

const SIZE := 100


func _draw() -> void:
	var p = get_global_mouse_position()
	draw_line(Vector2(0, p.y), Vector2(800, p.y), Color.YELLOW)
	draw_line(Vector2(p.x, 0), Vector2(p.x, 600), Color.YELLOW)
