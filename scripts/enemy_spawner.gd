extends Node2D

@export var wave: WaveConfig
@export var arena_center: Vector2 = Vector2.ZERO
@export var spawn_radius: float = 880.0
@export var min_spawn_interval: float = 0.35
@export var spawn_acceleration_per_minute: float = 0.3
@export var extra_enemy_every_seconds: float = 22.0
@export var max_extra_enemies: int = 5

var _cooldown: float = 0.0


func _ready() -> void:
	if wave == null:
		wave = WaveConfig.new()


func _process(delta: float) -> void:
	if not GameState.match_active:
		return
	if wave.enemy_scene == null:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = _get_current_spawn_interval()
		for _i in range(_get_current_enemies_per_tick()):
			_spawn_one()


func _get_current_spawn_interval() -> float:
	var minutes_alive := GameState.survival_time / 60.0
	var accelerated := wave.spawn_interval - minutes_alive * spawn_acceleration_per_minute
	return maxf(min_spawn_interval, accelerated)


func _get_current_enemies_per_tick() -> int:
	var extra := int(floor(GameState.survival_time / extra_enemy_every_seconds))
	return wave.enemies_per_tick + mini(extra, max_extra_enemies)


func _spawn_one() -> void:
	var enemy := wave.enemy_scene.instantiate() as Node2D
	var ang := randf() * TAU
	enemy.global_position = arena_center + Vector2.RIGHT.rotated(ang) * spawn_radius
	var enemies_root := get_tree().get_first_node_in_group("enemies_root") as Node2D
	if enemies_root:
		enemies_root.add_child(enemy)
