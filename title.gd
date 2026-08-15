extends Control


func _process(delta: float) -> void:
	if Input.is_action_pressed("start"):
		get_tree().change_scene_to_file("res://main.tscn")
