extends Node2D

const GRID_SIZE := Vector2i(48, 36)
const GRID_SPACING := 20.0
# const GRID_SIZE := Vector2i(96, 72)
# const GRID_SPACING := 10.0
const SPRING_K := 320.0
const NEIGHBOR_K := 0.8
const DAMPING := 0.90

# var force_radius := 100.0
# var force_strength := -2000.0

@export var grid_color: Color = Color.GREEN_YELLOW

var rest_positions := PackedVector2Array()
var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var idxs := PackedInt32Array()
var didxs := PackedInt32Array()
var draw_points := PackedVector2Array()

var flag := false

var force_pos := Vector2.ZERO
var force := 0.0
var force_radius := 0.0
var forces := PackedVector4Array()
var forces_size := 0


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

	forces.resize(400)
	draw_points.resize(didxs.size())


func set_data(_bs: PackedByteArray, ps: PackedVector2Array, fs: PackedVector2Array) -> void:
	forces_size = 0
	for i in _bs.size():
		if _bs[i] == 1 && fs[i] != Vector2.ZERO:
			forces[forces_size].x = ps[i].x + 80.0
			forces[forces_size].y = ps[i].y + 80.0
			forces[forces_size].z = fs[i].x
			forces[forces_size].w = fs[i].y
			forces_size += 1


func update(delta: float) -> void:
	for i in forces_size:
		var lx = forces[i].x - forces[i].z
		var rx = forces[i].x + forces[i].z
		var ly = forces[i].y - forces[i].z
		var ry = forces[i].y + forces[i].z
		lx = floor(lx / GRID_SPACING)
		rx = ceil(rx / GRID_SPACING)
		ly = floor(ly / GRID_SPACING)
		ry = ceil(ry / GRID_SPACING)

		var r_sq = forces[i].z * forces[i].z
		for y in range(max(ly - 1, 0), min(ry + 1, GRID_SIZE.y)):
			for x in range(max(lx - 1, 0), min(rx + 1, GRID_SIZE.x)):
				var idx = get_idx(x, y)
				var spos = positions[idx]
				var fpos = Vector2(forces[i].x, forces[i].y)
				# TODO: distance_to_sqrt
				var d = spos - fpos
				# var dist_sq = d.x * d.x + d.y * d.y
				var dist_sq = spos.distance_squared_to(fpos)
				if dist_sq < r_sq:
					var dir = d.normalized()
					# TODO: facの関数について
					# var fac = dist_sq / r_sq
					var fac = cos(sqrt(dist_sq) / forces[i].z)
					# velocities[idx] += dir * forces[i].w * fac * delta
					velocities[idx] += d * forces[i].w * delta

	update_physics(delta)
	queue_redraw()


func update_physics(delta: float) -> void:
	var start = Time.get_ticks_usec()
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

	var i = 0
	for idx in didxs:
		draw_points[i] = positions[idx]
		i += 1

	var end = Time.get_ticks_usec()
	print(end - start)


func _draw() -> void:
	draw_multiline(draw_points, grid_color)


func get_idx(x: int, y: int) -> int:
	return GRID_SIZE.x * y + x
