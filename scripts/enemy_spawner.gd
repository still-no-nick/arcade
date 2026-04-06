extends Node2D

const CHASER_STATS := preload("res://resources/enemies/chaser_enemy.tres")
const TANK_STATS := preload("res://resources/enemies/tank_enemy.tres")
const RUSHER_STATS := preload("res://resources/enemies/rusher_enemy.tres")
const ELITE_STATS := preload("res://resources/enemies/elite_enemy.tres")

const PHASES := [
	{
		"start": 0.0,
		"name": "OPENING BREACH",
		"interval_multiplier": 1.0,
		"bonus_per_tick": 0,
		"weights": {"chaser": 10, "tank": 0, "rusher": 0},
	},
	{
		"start": 55.0,
		"name": "HUNTER SWARM",
		"interval_multiplier": 0.92,
		"bonus_per_tick": 0,
		"weights": {"chaser": 7, "tank": 1, "rusher": 4},
	},
	{
		"start": 120.0,
		"name": "SIEGE PUSH",
		"interval_multiplier": 0.85,
		"bonus_per_tick": 1,
		"weights": {"chaser": 6, "tank": 3, "rusher": 4},
	},
	{
		"start": 210.0,
		"name": "PRESSURE SPIKE",
		"interval_multiplier": 0.78,
		"bonus_per_tick": 1,
		"weights": {"chaser": 5, "tank": 4, "rusher": 6},
	},
]

const ELITE_SPAWN_TIMES := [180.0, 300.0]

@export var wave: WaveConfig
@export var arena_center: Vector2 = Vector2.ZERO
@export var spawn_radius: float = 880.0
@export var min_spawn_interval: float = 0.35
@export var spawn_acceleration_per_minute: float = 0.3
@export var extra_enemy_every_seconds: float = 22.0
@export var max_extra_enemies: int = 5

var _cooldown: float = 0.0
var _elite_index: int = 0


func _ready() -> void:
	if wave == null:
		wave = WaveConfig.new()
	GameState.set_match_phase(PHASES[0]["name"])


func _process(delta: float) -> void:
	if not GameState.match_active:
		return
	if wave.enemy_scene == null:
		return
	var phase := _get_current_phase()
	GameState.set_match_phase(String(phase["name"]))
	_try_spawn_elite()
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = _get_current_spawn_interval(phase)
		for _i in range(_get_current_enemies_per_tick(phase)):
			_spawn_one(phase)


func _get_current_phase() -> Dictionary:
	var current_phase: Dictionary = PHASES[0]
	for phase in PHASES:
		if GameState.survival_time >= float(phase["start"]):
			current_phase = phase
		else:
			break
	return current_phase


func _get_current_spawn_interval(phase: Dictionary) -> float:
	var minutes_alive := GameState.survival_time / 60.0
	var accelerated := wave.spawn_interval - minutes_alive * spawn_acceleration_per_minute
	return maxf(min_spawn_interval, accelerated * float(phase["interval_multiplier"]))


func _get_current_enemies_per_tick(phase: Dictionary) -> int:
	var extra := int(floor(GameState.survival_time / extra_enemy_every_seconds))
	return wave.enemies_per_tick + mini(extra, max_extra_enemies) + int(phase["bonus_per_tick"])


func _spawn_one(phase: Dictionary, force_enemy_id: String = "") -> void:
	var enemy := wave.enemy_scene.instantiate() as Node2D
	var enemy_id := force_enemy_id
	if enemy_id.is_empty():
		enemy_id = _pick_enemy_id(phase)
	enemy.set("stats", _get_enemy_stats(enemy_id).duplicate(true))
	var ang := randf() * TAU
	enemy.global_position = arena_center + Vector2.RIGHT.rotated(ang) * spawn_radius
	var enemies_root := get_tree().get_first_node_in_group("enemies_root") as Node2D
	if enemies_root:
		enemies_root.add_child(enemy)


func _pick_enemy_id(phase: Dictionary) -> String:
	var weights: Dictionary = phase["weights"]
	var total_weight := 0
	for enemy_id in weights.keys():
		total_weight += int(weights[enemy_id])
	if total_weight <= 0:
		return "chaser"
	var roll := randi_range(1, total_weight)
	var cursor := 0
	for enemy_id in ["chaser", "tank", "rusher"]:
		cursor += int(weights.get(enemy_id, 0))
		if roll <= cursor:
			return enemy_id
	return "chaser"


func _get_enemy_stats(enemy_id: String) -> EnemyStats:
	match enemy_id:
		"tank":
			return TANK_STATS
		"rusher":
			return RUSHER_STATS
		"elite":
			return ELITE_STATS
		_:
			return CHASER_STATS


func _try_spawn_elite() -> void:
	if _elite_index >= ELITE_SPAWN_TIMES.size():
		return
	if GameState.survival_time < ELITE_SPAWN_TIMES[_elite_index]:
		return
	_spawn_one(_get_current_phase(), "elite")
	_elite_index += 1
