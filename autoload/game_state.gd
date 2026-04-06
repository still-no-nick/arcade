extends Node

signal level_up_choices(new_level: int, choices: Array)
signal xp_changed(current: int, needed: int)
signal player_died
signal match_reset

const DEFAULT_UPGRADES := [
	preload("res://resources/upgrades/damage_upgrade.tres"),
	preload("res://resources/upgrades/fire_rate_upgrade.tres"),
	preload("res://resources/upgrades/move_speed_upgrade.tres"),
	preload("res://resources/upgrades/max_health_upgrade.tres"),
]

var xp: int = 0
var level: int = 1
var xp_to_next: int = 10
var survival_time: float = 0.0
var is_choosing_upgrade: bool = false
var match_active: bool = true


func reset_match() -> void:
	match_active = true
	xp = 0
	level = 1
	xp_to_next = 10
	survival_time = 0.0
	is_choosing_upgrade = false
	match_reset.emit()
	xp_changed.emit(xp, xp_to_next)


func add_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp, xp_to_next)
	_try_advance_level()


func _try_advance_level() -> void:
	if is_choosing_upgrade:
		return
	if xp < xp_to_next:
		return
	xp -= xp_to_next
	level += 1
	xp_to_next = int(xp_to_next * 1.25) + 8
	xp_changed.emit(xp, xp_to_next)
	is_choosing_upgrade = true
	get_tree().paused = true
	var pool := DEFAULT_UPGRADES.duplicate()
	pool.shuffle()
	var choices: Array = pool.slice(0, mini(3, pool.size()))
	level_up_choices.emit(level, choices)


func upgrade_chosen(_choice_id: String) -> void:
	is_choosing_upgrade = false
	_try_advance_level()
	if not is_choosing_upgrade:
		get_tree().paused = false


func notify_player_died() -> void:
	match_active = false
	player_died.emit()
