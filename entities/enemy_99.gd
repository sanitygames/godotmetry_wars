extends Entity

const SPEED := 600.0
signal e9_hit_shot(area: Area2D)
signal e9_death(id: int)

var dir := Vector2.INF
var life := 1
var speed := SPEED


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	if dir == Vector2.INF:
		dir = (_d.pp - position).normalized()

	position += speed * dir * delta
	speed = max(speed * 0.97, 200.0)

	return position


func _on_area_entered(area: Entity) -> void:
	if visible:
		if area is Player:
			print(area, ":PLAYER * ENEMY99")
		if area is Bullet && position != Vector2(9999, 9999):
			e9_hit_shot.emit(area)
			life -= 1
			if life <= 0:
				e9_death.emit(id)
				life = 1
				speed = SPEED
				dir = Vector2.INF
