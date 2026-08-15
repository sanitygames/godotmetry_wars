extends Entity
class_name Bullet

const SPEED := 600


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	position.x += cos(rotation) * SPEED * delta
	position.y += sin(rotation) * SPEED * delta
	return position
