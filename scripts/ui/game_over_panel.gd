extends PanelContainer

@onready var _result_label: Label = %ResultLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_restart_button.pressed.connect(_on_restart)


func show_panel() -> void:
	visible = true
	pivot_offset = size * 0.5
	scale = Vector2(0.9, 0.9)
	modulate.a = 0.0
	_result_label.text = "Пилот удерживал арену %.1f секунд" % GameState.survival_time
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.24)


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
