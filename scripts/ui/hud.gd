extends Control

@onready var _time_label: Label = $TimeLabel
@onready var _xp_label: Label = $XPLabel
@onready var _health_label: Label = $HealthLabel


func _ready() -> void:
	GameState.xp_changed.connect(_on_xp_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_on_xp_changed(GameState.xp, GameState.xp_to_next)
	_bind_player_health()


func _process(_delta: float) -> void:
	var extra := ""
	if (
		get_tree().paused
		and GameState.match_active
		and not GameState.is_choosing_upgrade
	):
		extra = "  [ПАУЗА]"
	_time_label.text = "Время: %.1f с%s" % [GameState.survival_time, extra]


func _on_xp_changed(current: int, needed: int) -> void:
	_xp_label.text = "XP %d / %d  ·  Ур. %d" % [current, needed, GameState.level]


func _bind_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		_health_label.text = "HP: -- / --"
		return
	var health := player.get_node_or_null("Health") as Health
	if health == null:
		_health_label.text = "HP: -- / --"
		return
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current, health.max_health)


func _on_health_changed(current: float, max_health: float) -> void:
	_health_label.text = "HP: %d / %d" % [int(round(current)), int(round(max_health))]


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	if GameState.is_choosing_upgrade or not GameState.match_active:
		return
	get_tree().paused = not get_tree().paused
	get_viewport().set_input_as_handled()
