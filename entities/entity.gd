@abstract extends Node2D
class_name Entity

@export var max_life := 1
var id := 0
var life := 1

@abstract func move(delta: float, _d: Dictionary = {}) -> Vector2

func spawn(pos: Vector2) -> void:
	life = max_life
	position = pos
	set_deferred("monitoring", true)

func death() -> void:
	set_deferred("monitoring", false)
