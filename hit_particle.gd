extends GPUParticles2D

signal hit_finished(id)

var id = 0


func _on_finished() -> void:
	hit_finished.emit(id)
