extends Entity
class_name Bullet

const SPEED := 600

var dir := Vector2.INF


func initialize(_id: int) -> void:
	position = DEF_VEC2
	id = _id


func spawn(_pos: Vector2, _rot: float = 0.0) -> void:
	position = _pos
	rotation = _rot


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	position.x += cos(rotation) * SPEED * delta
	position.y += sin(rotation) * SPEED * delta
	return position


func death() -> void:
	position = DEF_VEC2
