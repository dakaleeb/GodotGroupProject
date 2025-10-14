extends Node2D
@onready var door = $greendoor
@onready var keyCard = $keyCard

func _ready():
	door.visible = false
	keyCard.connect("keycard_collected",Callable(self, "_on_keycard_collected"))

func _on_keycard_collected():
	door.visible = true
