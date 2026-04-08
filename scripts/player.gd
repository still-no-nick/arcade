extends CharacterBody2D

const FeedbackHelper := preload("res://scripts/helpers/feedback_helper.gd")

@export var weapon_stats: WeaponStats
@export var move_speed: float = 240.0
@export var base_pickup_radius: float = 90.0

@onready var _health: Health = $Health
@onready var _visual: Sprite2D = %Visual

var pickup_radius: float = 90.0
var regen_per_second: float = 0.0

var _base_weapon_stats: WeaponStats
var _base_move_speed: float = 240.0
var _base_max_health: float = 100.0
var _last_max_health: float = 100.0
var _base_visual_scale: Vector2 = Vector2.ONE
var _stat_flats: Dictionary = {}
var _stat_multipliers: Dictionary = {}
var _tag_counts: Dictionary = {}


func _ready() -> void:
	add_to_group("player")
	if weapon_stats == null:
		weapon_stats = WeaponStats.new()
	weapon_stats = weapon_stats.duplicate(true)
	_base_weapon_stats = weapon_stats.duplicate(true)
	_base_move_speed = move_speed
	_base_max_health = _health.max_health
	_last_max_health = _health.max_health
	_base_visual_scale = _visual.scale
	pickup_radius = base_pickup_radius
	_health.damaged.connect(_on_health_damaged)
	_health.depleted.connect(_on_health_depleted)
	_rebuild_stats()


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * move_speed
	move_and_slide()
	_update_visual_feedback(delta)
	if regen_per_second > 0.0 and _health.current < _health.max_health:
		_health.heal(regen_per_second * delta)


func apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return
	_apply_upgrade_stat(String(upgrade.stat), upgrade.additive, upgrade.multiplier)
	_apply_upgrade_stat(String(upgrade.secondary_stat), upgrade.secondary_additive, upgrade.secondary_multiplier)
	for tag in upgrade.tags:
		var key := String(tag)
		_tag_counts[key] = int(_tag_counts.get(key, 0)) + 1
	_rebuild_stats()


func _on_health_damaged(_amount: float) -> void:
	_visual.modulate = Color(1.0, 0.55, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(_visual, "scale", _base_visual_scale * Vector2(1.22, 0.84), 0.08).from(_visual.scale)
	tween.tween_property(_visual, "scale", _base_visual_scale, 0.14)
	var feedback := FeedbackHelper.get_feedback(self)
	if feedback and feedback.has_method("play_player_hurt"):
		feedback.play_player_hurt(global_position)


func _on_health_depleted() -> void:
	var feedback := FeedbackHelper.get_feedback(self)
	if feedback and feedback.has_method("play_player_death"):
		feedback.play_player_death(global_position)
	GameState.notify_player_died()


func _apply_upgrade_stat(stat_name: String, additive: float, multiplier: float) -> void:
	if stat_name.is_empty():
		return
	if additive != 0.0:
		_stat_flats[stat_name] = float(_stat_flats.get(stat_name, 0.0)) + additive
	if multiplier != 1.0:
		_stat_multipliers[stat_name] = float(_stat_multipliers.get(stat_name, 1.0)) * multiplier


func _rebuild_stats() -> void:
	var flats: Dictionary = _stat_flats.duplicate(true)
	var multipliers: Dictionary = _stat_multipliers.duplicate(true)
	_apply_synergies(flats, multipliers)

	weapon_stats.damage = _resolve_stat(_base_weapon_stats.damage, "damage", flats, multipliers)
	weapon_stats.fire_rate = maxf(0.25, _resolve_stat(_base_weapon_stats.fire_rate, "fire_rate", flats, multipliers))
	weapon_stats.projectile_speed = maxf(180.0, _resolve_stat(_base_weapon_stats.projectile_speed, "projectile_speed", flats, multipliers))
	weapon_stats.projectile_count = maxi(1, int(round(_resolve_stat(float(_base_weapon_stats.projectile_count), "projectile_count", flats, multipliers))))
	weapon_stats.spread_degrees = maxf(0.0, _resolve_stat(_base_weapon_stats.spread_degrees, "spread_degrees", flats, multipliers))
	weapon_stats.pierce = maxi(0, int(round(_resolve_stat(float(_base_weapon_stats.pierce), "pierce", flats, multipliers))))
	weapon_stats.crit_chance = clampf(_resolve_stat(_base_weapon_stats.crit_chance, "crit_chance", flats, multipliers), 0.0, 0.9)
	weapon_stats.crit_multiplier = maxf(1.1, _resolve_stat(_base_weapon_stats.crit_multiplier, "crit_multiplier", flats, multipliers))
	weapon_stats.damage_multiplier = maxf(0.2, _resolve_stat(_base_weapon_stats.damage_multiplier, "damage_multiplier", flats, multipliers))
	move_speed = maxf(90.0, _resolve_stat(_base_move_speed, "move_speed", flats, multipliers))
	pickup_radius = maxf(40.0, _resolve_stat(base_pickup_radius, "pickup_radius", flats, multipliers))
	regen_per_second = maxf(0.0, _resolve_stat(0.0, "regen", flats, multipliers))
	_apply_max_health(maxf(30.0, _resolve_stat(_base_max_health, "max_health", flats, multipliers)))

	var weapon := get_node_or_null("AutoWeapon")
	if weapon and weapon.has_method("update_fire_rate"):
		weapon.update_fire_rate()


func _resolve_stat(base_value: float, stat_name: String, flats: Dictionary, multipliers: Dictionary) -> float:
	return base_value * float(multipliers.get(stat_name, 1.0)) + float(flats.get(stat_name, 0.0))


func _apply_synergies(flats: Dictionary, multipliers: Dictionary) -> void:
	if _has_tags(["volley", "pierce"]):
		flats["damage_multiplier"] = float(flats.get("damage_multiplier", 0.0)) + 0.22
		flats["projectile_speed"] = float(flats.get("projectile_speed", 0.0)) + 40.0
	if _has_tags(["crit", "overclock"]):
		flats["crit_chance"] = float(flats.get("crit_chance", 0.0)) + 0.12
		flats["fire_rate"] = float(flats.get("fire_rate", 0.0)) + 0.25
	if _has_tags(["mobility", "utility"]):
		flats["move_speed"] = float(flats.get("move_speed", 0.0)) + 18.0
		flats["pickup_radius"] = float(flats.get("pickup_radius", 0.0)) + 55.0
	if _has_tags(["defense", "regen"]):
		flats["max_health"] = float(flats.get("max_health", 0.0)) + 12.0
		flats["regen"] = float(flats.get("regen", 0.0)) + 0.75
	if _has_tag("arsenal", 2):
		multipliers["damage"] = float(multipliers.get("damage", 1.0)) * 1.05


func _has_tags(required_tags: Array[String]) -> bool:
	for tag in required_tags:
		if int(_tag_counts.get(tag, 0)) <= 0:
			return false
	return true


func _has_tag(tag_name: String, min_count: int = 1) -> bool:
	return int(_tag_counts.get(tag_name, 0)) >= min_count


func _apply_max_health(new_max_health: float) -> void:
	var old_max := _last_max_health
	_health.max_health = new_max_health
	if new_max_health > old_max:
		_health.current = minf(_health.current + (new_max_health - old_max), new_max_health)
	else:
		_health.current = minf(_health.current, new_max_health)
	_health.health_changed.emit(_health.current, _health.max_health)
	_last_max_health = new_max_health


func get_pickup_radius() -> float:
	return pickup_radius


func _update_visual_feedback(delta: float) -> void:
	var speed_ratio := clampf(velocity.length() / maxf(move_speed, 1.0), 0.0, 1.0)
	var target_rotation := velocity.x * 0.0018
	var target_scale := _base_visual_scale * Vector2(1.0 + speed_ratio * 0.08, 1.0 - speed_ratio * 0.05)
	_visual.rotation = lerpf(_visual.rotation, target_rotation, minf(1.0, delta * 10.0))
	_visual.scale = _visual.scale.lerp(target_scale, minf(1.0, delta * 8.0))
