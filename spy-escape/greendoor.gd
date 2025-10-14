extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if visible:
		if body.name == "Player":
			get_tree().reload_current_scene()
	pass # Replace with function body.
