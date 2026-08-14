extends Node2D

const GRID_SIZE: Vector2i = Vector2i(80, 60)
const SPACING: float = 10.0

var rest_positions: PackedVector2Array = []
var positions: PackedVector2Array = []
var velocities: PackedVector2Array = []


func _ready() -> void:
	for i in GRID_SIZE.x * GRID_SIZE.y:
		rest_positions.append(Vector2.ZERO)
		positions.append(Vector2.ZERO)
		velocities.append(Vector2.ZERO)

	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var pos = Vector2(x, y) * SPACING
			rest_positions[idx(x, y)] = pos
			positions[idx(x, y)] = pos
			velocities[idx(x, y)] = Vector2.ZERO


func idx(x: int, y: int) -> int:
	return GRID_SIZE.x * y + x
