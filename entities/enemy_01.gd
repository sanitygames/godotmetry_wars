extends Entity

const SPEED := 30.0
const MAX_LIFE := 16
# signal e2_hit_shot(shot: Area2D)
# signal e2_death(id: int)
# signal e2_shot(id: int)

var target := Vector2.INF

var time := 0.0


func _ready() -> void:
	max_life = MAX_LIFE


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	if target == Vector2.INF:
		target = [Vector2(100, 100), Vector2(100, 500), Vector2(700, 100), Vector2(700, 500)][
			randi() % 4
		]

	var dir = (target - position).normalized()
	position += dir * SPEED * delta
	rotate(delta * 5.0)
	# position = target

	time += delta
	if time >= 0.4:
		time = 0.0
		if 0 < position.x && position.x < 800 && 0 < position.y && position.y < 600:
			shoot.emit(id)

	return position


func _on_area_entered(shot: Entity) -> void:
	hit.emit(shot)
	life -= 1
	if life <= 0:
		dead.emit(id)
		target = Vector2.INF
		death()
