extends PanelContainer

@onready var _result_label: Label = $Margin/VBox/ResultLabel
@onready var _restart_button: Button = $Margin/VBox/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_restart_button.pressed.connect(_on_restart)


func show_panel() -> void:
	visible = true
	_result_label.text = "Вы продержались %.1f с" % GameState.survival_time


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
