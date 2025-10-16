extends RichTextLabel

var player

func _ready() -> void:
	player = get_node("../Player.tscn")
	return
	
func _process(delta: float) -> void:
	
