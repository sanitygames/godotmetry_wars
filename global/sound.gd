extends CanvasLayer

var volume := 50
var is_title := true
var timer := 0.0

var hit_flag := true
var hit_timer := 0.0
var shot_flag := true
var shot_timer := 0.0

@onready var _bomb := $Bomb
@onready var _hit := $Hit
@onready var _shot := $Shot
@onready var _game_over := $GameOver


func _ready() -> void:
	var idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(idx, volume / 100.0)
	print(AudioServer.get_bus_volume_db(idx))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("volume_up"):
		volume = clamp(volume + 5, 0, 100)
	elif event.is_action_pressed("volume_down"):
		volume = clamp(volume - 5, 0, 100)
	else:
		return

	print(volume)
	var idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(idx, volume / 100.0)

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
	_bomb.pitch_scale = p
	_bomb.play()


func hit(p: float) -> void:
	if hit_flag:
		hit_flag = false
		_hit.pitch_scale = p
		_hit.play()


func shot() -> void:
	if shot_flag:
		shot_flag = false
		_shot.play()


func game_over() -> void:
	_game_over.play()
