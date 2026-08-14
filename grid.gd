extends Node2D

const GRID_SIZE := Vector2i(48, 48)
const GRID_SPACING := 20.0
const SPRING_K := 210.0
const NEIGHBOR_K := 2.3
const DAMPING := 0.97

# var force_radius := 100.0
# var force_strength := -2000.0

@export var grid_color: Color = Color.GREEN_YELLOW

var rest_positions := PackedVector2Array()
var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var idxs := PackedInt32Array()
var didxs := PackedInt32Array()

var flag := false

var force_pos := Vector2.ZERO
var force := 0.0
var force_radius := 0.0
var forces := []


func _ready() -> void:
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var pos = Vector2(x, y) * GRID_SPACING
			rest_positions.append(pos)
			positions.append(pos)
			velocities.append(Vector2.ZERO)
			if x == 0 || x == GRID_SIZE.x - 1 || y == 0 || y == GRID_SIZE.y - 1:
				continue
			idxs.append(get_idx(x, y))

	for y in GRID_SIZE.y - 1:
		for x in GRID_SIZE.x - 1:
			didxs.append(get_idx(x, y))
			didxs.append(get_idx(x + 1, y))
			didxs.append(get_idx(x, y))
			didxs.append(get_idx(x, y + 1))


func set_data(_bs: PackedByteArray, ps: PackedVector2Array, fs: PackedVector2Array) -> void:
	forces.clear()
	for i in _bs.size():
		if _bs[i] == 1:
			forces.append([ps[i], fs[i].x, fs[i].y])


func update(delta: float) -> void:
	for _force in forces:
		apply_force(_force[0] + Vector2(80, 80), delta, _force[1], _force[2])

	update_physics(delta)
	queue_redraw()


func apply_force(pos: Vector2, delta: float, _force_radius: float, force_strength: float) -> void:
	for idx in idxs:
		var dist = pos.distance_to(positions[idx])
		if dist < _force_radius:
			var dir = (pos - positions[idx]).normalized()
			var fac = cos(dist / _force_radius)
			velocities[idx] += dir * force_strength * fac * delta


func update_physics(delta: float) -> void:
	for idx in idxs:
		var pos = positions[idx]
		var f = (rest_positions[idx] - pos) * SPRING_K
		f += (positions[idx - 1] - pos) * NEIGHBOR_K
		f += (positions[idx + 1] - pos) * NEIGHBOR_K
		f += (positions[idx - GRID_SIZE.y] - pos) * NEIGHBOR_K
		f += (positions[idx + GRID_SIZE.y] - pos) * NEIGHBOR_K
		velocities[idx] += f * delta
		velocities[idx] *= DAMPING
		positions[idx] += velocities[idx] * delta


func _draw() -> void:
	var _ps = PackedVector2Array()
	for idx in didxs:
		_ps.append(positions[idx])

	draw_multiline(_ps, grid_color)


func get_idx(x: int, y: int) -> int:
	return GRID_SIZE.x * y + x
