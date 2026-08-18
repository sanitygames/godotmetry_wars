extends Entity
class_name Player

const SPEED := 300.0

var is_move := false


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	is_move = false
	var dpos := Vector2.ZERO
	if Input.is_action_pressed("left"):
		dpos.x -= 1
		is_move = true
	if Input.is_action_pressed("right"):
		dpos.x += 1
		is_move = true
	if Input.is_action_pressed("up"):
		dpos.y -= 1
		is_move = true
	if Input.is_action_pressed("down"):
		dpos.y += 1
		is_move = true
	position += dpos.normalized() * SPEED * delta

	position.x = clamp(position.x, 0, 800)
	position.y = clamp(position.y, 0, 600)

	look_at(get_global_mouse_position())
	return position


func _on_area_entered(_enemy: Entity) -> void:
	dead.emit(_enemy.id)
