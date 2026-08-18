extends CanvasLayer

var ticks_values := {}
var ticks_strings := {}
var flags_strings := []

var count = 0

@onready var label: Label = $Label


## 表示のトグル
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click_right"):
		visible = !visible


## 関数の処理速度(usec)の取得と表示
func ticks_usec(s: String, start: float, end: float) -> void:
	if ticks_values.has(s):
		ticks_values[s][count % ticks_values[s].size()] = (end - start) / 1000.0
	else:
		ticks_values[s] = []
		ticks_values[s].resize(60)
		ticks_values[s].fill(0.0)

	var v: float = ticks_values[s].max()

	var ticks_text = "%s: %.02f[ms]\n" % [s, v]
	ticks_strings[s] = ticks_text


## アクティブentity数の取得と表示
func set_flags(flags: Array, idxs: Array, names: Array) -> void:
	flags_strings.clear()
	for i in idxs.size() - 1:
		var s = flags.slice(idxs[i], idxs[i + 1]).count(1)
		flags_strings.append("%s: %s / %d\n" % [names[i], s, idxs[i + 1] - idxs[i]])


## Labelの更新
func update() -> void:
	count += 1
	label.text = "FPS: %d\n" % [Engine.get_frames_per_second()]
	for key in ticks_strings:
		label.text += ticks_strings[key]
	for s in flags_strings:
		label.text += s
