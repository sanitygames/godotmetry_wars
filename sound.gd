extends CanvasLayer

var volume := 50
var is_title := true
var timer := 0.0

var hit_flag := true
var hit_timer := 0.0
var shot_flag := true
var shot_timer := 0.0


func _ready() -> void:
	var idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(idx, volume)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("volume_up"):
		volume = clamp(volume + 5, 0, 100)
	elif event.is_action_pressed("volume_down"):
		volume = clamp(volume - 5, 0, 100)
	else:
		return

	print(volume)
	var idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(idx, volume)

	if !is_title:
		timer = 0.0
		$Label.text = "Volume: %02d" % [volume]


func _process(delta: float) -> void:
	timer += delta
	$Label.self_modulate.a = 1.0 - min(1.0, timer * 0.5)

	if !hit_flag:
		hit_timer += delta
		if hit_timer > 0.03:
			hit_flag = true
			hit_timer = 0.0

	if !shot_flag:
		shot_timer += delta
		if shot_timer > 0.03:
			shot_flag = true
			shot_timer = 0.0


func bomb(p: float) -> void:
	$Bomb.pitch_scale = p
	$Bomb.play()


func hit(p: float) -> void:
	if hit_flag:
		hit_flag = false
		$Hit.pitch_scale = p
		$Hit.play()


func shot() -> void:
	if shot_flag:
		shot_flag = false
		$Shot.play()
