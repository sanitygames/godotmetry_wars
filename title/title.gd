extends Control

const MENU := "[S] tart     [-/+] volume:%02d"


func _ready() -> void:
	Sound.is_title = true


func _process(_delta: float) -> void:
	if Input.is_action_pressed("start"):
		get_tree().change_scene_to_file("res://main/main.tscn")

	$Menu.text = MENU % [Sound.volume]
