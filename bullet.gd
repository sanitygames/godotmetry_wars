extends Node2D

signal hitted(pos)
signal hit(id, pos, body)

var id := 0


func update(delta) -> Vector2:
	position.x += cos(rotation) * 700 * delta
	position.y += sin(rotation) * 700 * delta
	return position


func _on_area_2d_area_entered(area: Area2D) -> void:
	hitted.emit(position)


func _on_area_2d_body_entered(body: Node2D) -> void:
	hit.emit(id, position, body)
