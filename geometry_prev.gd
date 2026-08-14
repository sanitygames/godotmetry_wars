extends Node2D

# --- グリッド設定 ---
@export var grid_size: Vector2i = Vector2i(80, 60)  # 横・縦のマス数
@export var spacing: float = 10.0  # グリッドの初期感覚 (px)

# --- 物理パラメータ ---
@export var spring_k: float = 10.0  # 元の位置に戻るバネの強さ
@export var neighbor_k: float = 100.0  # 隣の点と引っ張り合う力（波の連鎖伝播）
@export var damping: float = 0.91  # 減衰率（1.0に近いほど長く揺れる）
@export var force_radius: float = 230.0  # 操作の影響範囲 (px)
@export var force_strength: float = 800.0  # 操作で与える力の強さ

# --- 質感・色設定 ---
@export var grid_color: Color = Color(0.0, 1.0, 0.0, 1.0)  # 発光感のあるシアン
@export var line_width: float = 1.0


# 質点クラス
class Point:
	var rest_position: Vector2
	var position: Vector2
	var velocity: Vector2 = Vector2.ZERO

	func _init(pos: Vector2):
		rest_position = pos
		position = pos


var points: Array = []


func _ready() -> void:
	# 質点配列の初期化
	for x in range(grid_size.x):
		var column: Array = []
		for y in range(grid_size.y):
			var pos = Vector2(x * spacing, y * spacing)
			column.append(Point.new(pos))
		points.append(column)


func _process(delta: float) -> void:
	var mouse_pos = get_local_mouse_position()

	# 左クリックまたはドラッグ中でグリッドを押し出す
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		apply_force(mouse_pos, delta)

	# 物理の更新処理
	update_physics(delta)

	# 描画を更新
	queue_redraw()


# 外力を加える（なぞった場所を押し出す）
func apply_force(impact_pos: Vector2, delta: float) -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pt = points[x][y] as Point
			var dist = pt.position.distance_to(impact_pos)

			if dist < force_radius and dist > 0:
				var dir = (pt.position - impact_pos).normalized()
				var factor = -cos(dist / force_radius)  # 近いほど強く
				pt.velocity += dir * force_strength * factor * delta


func update_physics(delta: float) -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pt = points[x][y] as Point

			# 1. 元の位置に戻ろうとする復元力
			var force = (pt.rest_position - pt.position) * spring_k * delta

			# 2. 隣接する質点との相互作用（波の拡散）
			if x > 0:
				var left = points[x - 1][y] as Point
				force += (left.position - pt.position) * neighbor_k * 0.1 * delta
			if x < grid_size.x - 1:
				var right = points[x + 1][y] as Point
				force += (right.position - pt.position) * neighbor_k * 0.1 * delta
			if y > 0:
				var up = points[x][y - 1] as Point
				force += (up.position - pt.position) * neighbor_k * 0.1 * delta
			if y < grid_size.y - 1:
				var down = points[x][y + 1] as Point
				force += (down.position - pt.position) * neighbor_k * 0.1 * delta

			# 3. 速度と位置の適用 + 減衰
			pt.velocity += force
			pt.velocity *= damping
			pt.position += pt.velocity * delta


func _draw() -> void:
	# 縦線を描画
	for x in range(grid_size.x):
		for y in range(grid_size.y - 1):
			var p1 = (points[x][y] as Point).position
			var p2 = (points[x][y + 1] as Point).position
			draw_line(p1, p2, grid_color, line_width)

	# 横線を描画
	for y in range(grid_size.y):
		for x in range(grid_size.x - 1):
			var p1 = (points[x][y] as Point).position
			var p2 = (points[x + 1][y] as Point).position
			draw_line(p1, p2, grid_color, line_width)
