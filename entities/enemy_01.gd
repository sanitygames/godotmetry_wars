extends Entity

const SPEED := 30.0
signal e2_hit_shot(area: Area2D)
signal e2_death(id: int)
signal e2_shot(id: int)

var target := Vector2.INF
var life := 30

var time := 0.0


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
		e2_shot.emit(id)

	return position


func _on_area_entered(area: Entity) -> void:
	if visible:
		if area is Player:
			print(area, " PLAYER")
		if area is Bullet:
			e2_hit_shot.emit(area)
			life -= 1
			if life <= 0:
				e2_death.emit(id)
				life = 20
				target = Vector2.INF
