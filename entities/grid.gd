extends Node2D

const GRID_SIZE := Vector2i(48, 36)
const GRID_SPACING := 20.0
const SPRING_K := 200.0
const NEIGHBOR_K := 40.8
const DAMPING := 0.90

@export var grid_color: Color = Color.GREEN_YELLOW

var rest_positions := PackedVector2Array()
var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var draw_points := PackedVector2Array()
var idxs := PackedInt32Array()
var didxs := PackedInt32Array()

var force_ps := PackedVector2Array()
var force_ds := PackedVector2Array()
var forces_size := 0


## 各種データ格納用PackedArrayの初期化
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
			didxs.append(get_idx(x + 1, y + 1))
			didxs.append(get_idx(x + 1, y))
			didxs.append(get_idx(x + 1, y + 1))
			didxs.append(get_idx(x, y + 1))

	force_ps.resize(400)
	force_ds.resize(400)
	draw_points.resize(didxs.size())


## Array[Entity]が持つデータのうち､
## アクティブかつ0パワーでないものをforce配列に格納
## force_ps: Vector2(position.x, position.y)
## foece_ds: Vector2(force_radius, force_power)
func set_data(_bs: PackedByteArray, ps: PackedVector2Array, fs: PackedVector2Array) -> void:
	var start = Time.get_ticks_usec()
	forces_size = 0
	for i in _bs.size():
		if _bs[i] == 1 && fs[i] != Vector2.ZERO:
			force_ps[forces_size] = ps[i] + Vector2(80, 80)
			force_ds[forces_size] = fs[i]
			forces_size += 1
	var end = Time.get_ticks_usec()
	Debugger.ticks_usec("Grid.set_data()", start, end)


## Gridがもつ質点毎のベロシティをvelocitiesに得る
## forceが明らかにかからない質点についてはスルー
func update(delta: float) -> void:
	var start = Time.get_ticks_usec()
	for i in forces_size:
		var lx = max(0, floor((force_ps[i].x - force_ds[i].x) / GRID_SPACING))
		var rx = min(ceil((force_ps[i].x + force_ds[i].x) / GRID_SPACING), GRID_SIZE.x)
		var ly = max(0, floor((force_ps[i].y - force_ds[i].x) / GRID_SPACING))
		var ry = min(ceil((force_ps[i].y + force_ds[i].x) / GRID_SPACING), GRID_SIZE.y)

		for y in range(ly, ry):
			for x in range(lx, rx):
				var idx = GRID_SIZE.x * y + x
				var distance = positions[idx].distance_to(force_ps[i])
				if distance < force_ds[i].x:
					var fac = sin(PI * distance / force_ds[i].x)
					var dir = force_ps[i].direction_to(positions[idx])
					velocities[idx] += dir * fac * force_ds[i].y * delta

	_update_positions(delta)
	queue_redraw()
	var end = Time.get_ticks_usec()
	Debugger.ticks_usec("Grid.update()", start, end)


## Gridがもつ質点毎の最終位置ををpositionsに得て､
## 描画用配列(draw_points)を生成
func _update_positions(delta: float) -> void:
	for idx in idxs:
		var pos = positions[idx]
		var f = (rest_positions[idx] - pos) * SPRING_K / NEIGHBOR_K
		f += positions[idx - 1] - pos
		f += positions[idx + 1] - pos
		f += positions[idx - GRID_SIZE.x] - pos
		f += positions[idx + GRID_SIZE.x] - pos
		velocities[idx] += f * NEIGHBOR_K * delta
		velocities[idx] *= DAMPING
		positions[idx] += velocities[idx] * delta

	var i = 0
	for idx in didxs:
		draw_points[i] = positions[idx]
		i += 1


## draw_pointsからグリッド線を描画
func _draw() -> void:
	draw_multiline(draw_points, grid_color)


func get_idx(x: int, y: int) -> int:
	return GRID_SIZE.x * y + x
