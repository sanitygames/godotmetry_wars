extends Control

var menu := "[S] tart\n[-/+] volume:%02d"


func _ready() -> void:
	Sound.is_title = true


func _process(_delta: float) -> void:
	if Input.is_action_pressed("start"):
		get_tree().change_scene_to_file("res://main.tscn")

	$Label2.text = menu % [Sound.volume]
