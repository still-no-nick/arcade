extends PanelContainer

@onready var _buttons_parent: VBoxContainer = %ButtonRow
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel


func _ready() -> void:
	GameState.level_up_choices.connect(_on_level_up_choices)
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _on_level_up_choices(new_level: int, choices: Array) -> void:
	visible = true
	_title_label.text = "УРОВЕНЬ %d" % new_level
	_subtitle_label.text = "Выбери протокол усиления для следующего боя."
	for c in _buttons_parent.get_children():
		c.queue_free()
	for opt in choices:
		if not (opt is UpgradeData):
			continue
		var selected_upgrade := opt as UpgradeData
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0.0, 92.0)
		btn.text = "%s\n%s" % [selected_upgrade.title, selected_upgrade.desc]
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color("eaf7ff"))
		btn.add_theme_color_override("font_pressed_color", Color("ffffff"))
		btn.add_theme_color_override("font_hover_color", Color("ffffff"))
		btn.add_theme_stylebox_override("normal", _make_button_style(Color("162338"), Color("32577e")))
		btn.add_theme_stylebox_override("hover", _make_button_style(Color("1d3450"), Color("79d6ff")))
		btn.add_theme_stylebox_override("pressed", _make_button_style(Color("244b72"), Color("bff2ff")))
		btn.pressed.connect(func(): _pick(selected_upgrade))
		_buttons_parent.add_child(btn)


func _pick(upgrade: UpgradeData) -> void:
	var game := get_tree().get_first_node_in_group("game_root")
	if game and game.has_method("apply_upgrade"):
		game.apply_upgrade(upgrade)
	hide()


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 22
	style.content_margin_top = 18
	style.content_margin_right = 22
	style.content_margin_bottom = 18
	return style
