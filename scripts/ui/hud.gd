extends Control

@onready var _time_label: Label = %TimeLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_label: Label = %XPLabel
@onready var _health_label: Label = %HealthLabel
@onready var _pause_label: Label = %PauseLabel
@onready var _xp_bar: ProgressBar = %XPBar
@onready var _health_bar: ProgressBar = %HealthBar

var _last_level: int = 1


func _ready() -> void:
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_level = GameState.level
	_on_xp_changed(GameState.xp, GameState.xp_to_next)
	_on_phase_changed(GameState.current_phase_name)
	_bind_player_health()


func _process(_delta: float) -> void:
	var extra := ""
	if (
		get_tree().paused
		and GameState.match_active
		and not GameState.is_choosing_upgrade
	):
		extra = "  •  ПАУЗА"
	_pause_label.visible = get_tree().paused and GameState.match_active and not GameState.is_choosing_upgrade
	_pause_label.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01))
	_time_label.text = "ВРЕМЯ  %.1f с%s" % [GameState.survival_time, extra]


func _on_xp_changed(current: int, needed: int) -> void:
	_level_label.text = "УРОВЕНЬ %d" % GameState.level
	_xp_label.text = "Опыт %d / %d" % [current, needed]
	_xp_bar.max_value = max(1, needed)
	var xp_tween := create_tween()
	xp_tween.tween_property(_xp_bar, "value", clamp(current, 0, needed), 0.18)
	if GameState.level != _last_level:
		_pulse_control(_level_label, Vector2(1.16, 1.16))
		_pulse_control(_xp_label, Vector2(1.06, 1.06))
		_last_level = GameState.level
	else:
		_pulse_control(_xp_label, Vector2(1.04, 1.04), 0.12)


func _on_phase_changed(phase_name: String) -> void:
	_phase_label.text = "PHASE  %s" % phase_name
	_pulse_control(_phase_label, Vector2(1.08, 1.08), 0.22)


func _bind_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		_health_label.text = "Корпус: -- / --"
		return
	var health := player.get_node_or_null("Health") as Health
	if health == null:
		_health_label.text = "Корпус: -- / --"
		return
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current, health.max_health)


func _on_health_changed(current: float, max_health: float) -> void:
	_health_label.text = "Корпус: %d / %d" % [int(round(current)), int(round(max_health))]
	_health_bar.max_value = maxf(1.0, max_health)
	var hp_tween := create_tween()
	hp_tween.tween_property(_health_bar, "value", clampf(current, 0.0, max_health), 0.16)
	_pulse_control(_health_label, Vector2(1.05, 1.05), 0.14)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	if GameState.is_choosing_upgrade or not GameState.match_active:
		return
	get_tree().paused = not get_tree().paused
	get_viewport().set_input_as_handled()


func _pulse_control(control: Control, peak_scale: Vector2, duration: float = 0.18) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", peak_scale, duration * 0.45).from(Vector2.ONE)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.55)
