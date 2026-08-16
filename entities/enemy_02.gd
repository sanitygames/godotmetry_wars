extends Entity

const SPEED := 32.0
const MAX_LIFE := 60
signal e3_hit_shot(area: Area2D)
signal e3_death(id: int)
signal e3_shot(id: int)

var target := Vector2(400, 300)

var time := 0.0


func _ready() -> void:
	max_life = MAX_LIFE


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	var dir = (target - position).normalized()
	position += dir * SPEED * delta
	rotation += delta

	time += delta
	if time >= 0.10:
		time = 0.0
		if 0 < position.x && position.x < 800 && 0 < position.y && position.y < 600:
			e3_shot.emit(id)

	return position


func _on_area_entered(area: Entity) -> void:
	e3_hit_shot.emit(area)
	life -= 1
	if life <= 0:
		e3_death.emit(id)
		target = Vector2.INF
		death()
