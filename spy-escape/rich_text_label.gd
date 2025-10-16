# File: SimpleStatusLabel.gd
extends RichTextLabel

@export var player_path: NodePath
@export var main_menu_path := "res://main_menu.tscn"

@export var fade_in_time := 0.8
@export var delay_before_menu := 1.5

@export var win_source_path: NodePath
@export var win_signal_name: StringName = "level_won"

var _player: Node
var _shown := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_active = false
	bbcode_enabled = false
	text = ""
	modulate.a = 0.0
	visible = false

	# Connect player death (uses your existing signal)
	if player_path != NodePath():
		_player = get_node(player_path)
		if _player and _player.has_signal("player_dead"):
			_player.connect("player_dead", Callable(self, "_on_player_dead"))

	# Optional: connect a win source
	if win_source_path != NodePath():
		var win_src := get_node(win_source_path)
		if win_src and win_src.has_signal(win_signal_name):
			win_src.connect(String(win_signal_name), Callable(self, "_on_win"))

func _on_player_dead() -> void:
	_show_and_exit("YOU DIED")

func _on_win() -> void:
	_show_and_exit("YOU WIN")

func show_win() -> void:
	_on_win()

func _show_and_exit(msg: String) -> void:
	if _shown:
		return
	_shown = true
	text = msg
	visible = true

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_time)
	tween.finished.connect(func ():
		await get_tree().create_timer(delay_before_menu).timeout
		get_tree().change_scene_to_file(main_menu_path))
