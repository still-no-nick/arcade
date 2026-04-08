extends Node

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const FeedbackHelper := preload("res://scripts/helpers/feedback_helper.gd")

@onready var _timer: Timer = $Timer
var _stats: WeaponStats
var _player: CharacterBody2D
var _projectiles_root: Node2D


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	_stats = _player.weapon_stats
	await get_tree().process_frame
	_projectiles_root = get_tree().get_first_node_in_group("projectiles_root") as Node2D
	_timer.timeout.connect(_on_fire)
	update_fire_rate()
	_timer.start()


func update_fire_rate() -> void:
	if _stats == null:
		return
	_timer.wait_time = maxf(0.08, 1.0 / _stats.fire_rate)


func _on_fire() -> void:
	if _stats == null or _projectiles_root == null:
		return
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var best: Node2D = null
	var best_d2 := INF
	var from := _player.global_position
	for n in enemies:
		var e := n as Node2D
		if e == null or not is_instance_valid(e):
			continue
		var d2 := from.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = e
	if best == null:
		return
	var dir := from.direction_to(best.global_position)
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	var projectile_count := maxi(1, _stats.projectile_count)
	var total_spread := _stats.spread_degrees
	var start_angle := -total_spread * 0.5
	var step := 0.0
	if projectile_count > 1:
		step = total_spread / float(projectile_count - 1)
	for index in range(projectile_count):
		var shot_dir := dir.rotated(deg_to_rad(start_angle + step * index))
		var proj := PROJECTILE_SCENE.instantiate() as Area2D
		proj.global_position = from + shot_dir * 28.0
		proj.velocity = shot_dir * _stats.projectile_speed
		var damage := _stats.damage * _stats.damage_multiplier
		var is_crit := randf() <= _stats.crit_chance
		if is_crit:
			damage *= _stats.crit_multiplier
		proj.damage = damage
		proj.pierce_left = _stats.pierce
		proj.is_crit = is_crit
		_projectiles_root.add_child(proj)
	var feedback := FeedbackHelper.get_feedback(self)
	if feedback and feedback.has_method("play_shot"):
		feedback.play_shot(from, dir, projectile_count)
