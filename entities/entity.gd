@abstract extends Node2D
class_name Entity

@warning_ignore_start("unused_signal")
signal hit(bullet: Entity)
signal dead(id: int)
signal shoot(id: int)

const DEF_VEC2 := Vector2(9999, 9999)

@export var max_life := 1
var id := 0
var life := 1

@abstract func move(delta: float, _d: Dictionary = {}) -> Vector2


## 生成時
func initialize(_id: int) -> void:
	position = DEF_VEC2
	id = _id
	set_deferred("monitoring", false)


## アクティブ開始時
func spawn(pos: Vector2, _rot: float = 0.0) -> void:
	life = max_life
	position = pos
	set_deferred("monitoring", true)
	

## アクティブ終了時
func death() -> void:
	set_deferred("monitoring", false)
	position = DEF_VEC2
