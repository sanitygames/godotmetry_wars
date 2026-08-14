extends Node2D

const GRID_SIZE := Vector2i(100, 100)
const GRID_SPACING := 10.0
const SPRING_K := 10.0
const NEIGHBOR_K := 30.0
const DAMPING := 0.90

# var force_radius := 100.0
# var force_strength := -2000.0

var rest_positions := PackedVector2Array()
var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var idxs := PackedInt32Array()
var didxs := PackedInt32Array()

var flag := false


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


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("click_left"):
		flag = true
	if !flag:
		return

	$Sprite2D.position = get_local_mouse_position()
	apply_force($Sprite2D.position, delta, 100.0, -2000.0)

	update_physics(delta)
	queue_redraw()


# func _process(delta: float) -> void:


func _on_timer_timeout() -> void:
	apply_force(
		Vector2(GRID_SIZE.x * randf(), GRID_SIZE.y * randf()) * GRID_SPACING, 0.016, 30.0, 2000.0
	)


func apply_force(pos: Vector2, delta: float, force_radius, force_strength) -> void:
	for idx in idxs:
		var dist = pos.distance_to(positions[idx])
		if dist < force_radius:
			var dir = (pos - positions[idx]).normalized()
			var fac = clamp(-sin(dist / force_radius), -0.3, 0.0)
			# var fac = -1.0
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

	draw_multiline(_ps, Color.GREEN_YELLOW)

	# for y in GRID_SIZE.y:
	# 	var ps = positions.slice(GRID_SIZE.x * y, GRID_SIZE.x * (y + 1))
	# 	draw_polyline(ps, Color.GREEN, 1.0)
	# for x in GRID_SIZE.x:
	# 	var ps = PackedVector2Array()
	# 	for y in GRID_SIZE.y:
	# 		ps.append(positions[get_idx(x, y)])
	# 	draw_polyline(ps, Color.GREEN, 1.0)


func get_idx(x: int, y: int) -> int:
	return GRID_SIZE.x * y + x
