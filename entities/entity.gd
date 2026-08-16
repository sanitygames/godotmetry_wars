@abstract extends Node2D
class_name Entity

var id = 0

@abstract func move(delta: float, _d: Dictionary = {}) -> Vector2
