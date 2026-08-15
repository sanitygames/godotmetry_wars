@tool
extends EditorPlugin

## godotplayer Score addon entry point.
## Registers the `GodotplayerScore` autoload singleton while the plugin is enabled.

const AUTOLOAD_NAME := "GodotplayerScore"
const AUTOLOAD_PATH := "res://addons/godotplayer_score/godotplayer_score.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
