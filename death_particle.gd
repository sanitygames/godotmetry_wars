extends GPUParticles2D

signal emit_finished(id)

var id = 0


func _on_finished() -> void:
	emit_finished.emit(id)
