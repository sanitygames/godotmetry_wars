extends TextureRect

@export var width: int = 1920 * 2
@export var height: int = 1080 * 2

# 1世代進める間隔（秒）。0.1秒 = 毎秒10世代
@export var update_interval: float = 0.0003
var time_passed: float = 0.0

var rd: RenderingDevice
var shader: RID
var pipeline: RID

var texture_a: RID
var texture_b: RID
var texture_rd_a: Texture2DRD
var texture_rd_b: Texture2DRD

var uniform_set_a: RID
var uniform_set_b: RID

var ping_pong: bool = true


func _ready() -> void:
	# ドット絵としてくっきり表示するために Nearest フィルタを適用
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	rd = RenderingServer.get_rendering_device()
	if not rd:
		return

	var shader_file = load("res://game_of_life.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

	var fmt = RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)

	var bytes_per_pixel = 4
	var total_bytes = width * height * bytes_per_pixel

	var initial_data = PackedByteArray()
	initial_data.resize(total_bytes)
	for i in range(width * height):
		var alive = randf() < 0.2
		var val: int = 255 if alive else 0
		var idx = i * 4
		initial_data[idx + 0] = val  # R (赤)
		initial_data[idx + 1] = val  # G (緑)
		initial_data[idx + 2] = val  # B (青)
		initial_data[idx + 3] = 255  # A (アルファ: 不透明)
	# 初期盤面の作成（黒でクリア）
	# var initial_data = PackedByteArray()
	# initial_data.resize(total_bytes)
	# for i in range(width * height):
	# 	initial_data[i * 4 + 3] = 255  # Alpha = 255

	# テスト用に画面中央に明確なパターンを書き込む
	var cx = width / 2
	var cy = height / 2

	# 1. ブリンカー (縦3マス)
	# _set_cell(initial_data, cx, cy - 1, true)
	# _set_cell(initial_data, cx, cy, true)
	# _set_cell(initial_data, cx, cy + 1, true)

	# # 2. グライダー (移動するパターン)
	# _set_cell(initial_data, cx + 10, cy, true)
	# _set_cell(initial_data, cx + 11, cy + 1, true)
	# _set_cell(initial_data, cx + 9, cy + 2, true)
	# _set_cell(initial_data, cx + 10, cy + 2, true)
	# _set_cell(initial_data, cx + 11, cy + 2, true)

	var empty_data = PackedByteArray()
	empty_data.resize(total_bytes)
	for i in range(width * height):
		empty_data[i * 4 + 3] = 255

	texture_a = rd.texture_create(fmt, RDTextureView.new(), [initial_data])
	texture_b = rd.texture_create(fmt, RDTextureView.new(), [empty_data])

	texture_rd_a = Texture2DRD.new()
	texture_rd_a.texture_rd_rid = texture_a

	texture_rd_b = Texture2DRD.new()
	texture_rd_b.texture_rd_rid = texture_b

	texture = texture_rd_a

	uniform_set_a = _create_uniform_set(texture_a, texture_b)
	uniform_set_b = _create_uniform_set(texture_b, texture_a)


# 指定座標のセルを 生/死 に設定するヘルパー関数
func _set_cell(data: PackedByteArray, x: int, y: int, alive: bool) -> void:
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	var idx = (y * width + x) * 4
	var val: int = 255 if alive else 0
	data[idx + 0] = val
	data[idx + 1] = val
	data[idx + 2] = val


func _create_uniform_set(read_tex: RID, write_tex: RID) -> RID:
	var u_read = RDUniform.new()
	u_read.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_read.binding = 0
	u_read.add_id(read_tex)

	var u_write = RDUniform.new()
	u_write.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_write.binding = 1
	u_write.add_id(write_tex)

	return rd.uniform_set_create([u_read, u_write], shader, 0)


func _process(delta: float) -> void:
	# 指定した間隔（update_interval）ごとにシミュレーションを実行
	time_passed += delta
	if time_passed < update_interval:
		return
	time_passed = 0.0

	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)

	var current_set = uniform_set_a if ping_pong else uniform_set_b
	rd.compute_list_bind_uniform_set(compute_list, current_set, 0)

	var x_groups = ceili(width / 16.0)
	var y_groups = ceili(height / 16.0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()

	# 表示テクスチャの切り替え
	texture = texture_rd_b if ping_pong else texture_rd_a

	ping_pong = !ping_pong
