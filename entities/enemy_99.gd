extends Entity

const SPEED := 600.0
const MAX_LIFE := 1
signal e9_hit_shot(area: Area2D)
signal e9_death(id: int)

var dir := Vector2.INF
var speed := SPEED

# func spawn(pos: Vector2) -> void:
# 	position = pos
# 	set_deferred("monitoring", true)


func _ready() -> void:
	max_life = MAX_LIFE


func move(delta: float, _d: Dictionary = {}) -> Vector2:
	if dir == Vector2.INF:
		dir = (_d.pp - position).normalized()

	position += speed * dir * delta
	speed = max(speed * 0.97, 200.0)

	return position


func _on_area_entered(area: Entity) -> void:
	e9_hit_shot.emit(area)
	life -= 1
	if life <= 0:
		set_deferred("monitoring", false)
		e9_death.emit(id)
		life = 1
		speed = SPEED
		dir = Vector2.INF
