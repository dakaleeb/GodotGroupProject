extends Area2D
signal keycard_collected
func _on_body_entered(body):
	if body.name == "Player":
		queue_free()
		emit_signal("keycard_collected")
