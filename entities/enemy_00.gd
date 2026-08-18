extends Entity

const SPEED := 100.0
const MAX_LIFE := 3

var accell := 1.0
var timer := 0.0
var target := Vector2(400, 300)


func _ready() -> void:
	max_life = MAX_LIFE


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	timer += delta
	rotation = (_d.pp - position).normalized().angle()
	if timer > 0.3:
		timer = 0.0
		target = _d.pp
	var dir = (target - position).normalized()
	position += dir * SPEED * delta * accell
	return position


func _on_area_entered(area: Entity) -> void:
	hit.emit(area)
	life -= 1
	if life <= 0:
		dead.emit(id)
		timer = 0.0
		death()
