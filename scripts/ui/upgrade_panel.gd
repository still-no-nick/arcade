extends PanelContainer

@onready var _buttons_parent: VBoxContainer = $Margin/VBox/ButtonRow


func _ready() -> void:
	GameState.level_up_choices.connect(_on_level_up_choices)
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _on_level_up_choices(_new_level: int, choices: Array) -> void:
	visible = true
	for c in _buttons_parent.get_children():
		c.queue_free()
	for opt in choices:
		if not (opt is UpgradeData):
			continue
		var selected_upgrade := opt as UpgradeData
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0.0, 64.0)
		btn.text = "%s\n%s" % [selected_upgrade.title, selected_upgrade.desc]
		btn.pressed.connect(func(): _pick(selected_upgrade))
		_buttons_parent.add_child(btn)


func _pick(upgrade: UpgradeData) -> void:
	var game := get_tree().get_first_node_in_group("game_root")
	if game and game.has_method("apply_upgrade"):
		game.apply_upgrade(upgrade)
	hide()
