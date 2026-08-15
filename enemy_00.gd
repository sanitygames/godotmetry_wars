extends Entity

const SPEED := 100.0

signal e1_hit_shot(area)
signal e1_death(id)

var accell := 1.0
var life := 5
var timer := 0.0
var target := Vector2(400, 300)


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
	if visible:
		if area is Player:
			print(area, " PLYER")
		if area is Bullet:
			e1_hit_shot.emit(area)
			life -= 1
			if life <= 0:
				e1_death.emit(id)
				life = 5
				timer = 0.0
