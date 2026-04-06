extends CharacterBody2D

const XP_PICKUP_SCENE := preload("res://scenes/xp_pickup.tscn")

@export var stats: EnemyStats
@onready var _health: Health = $Health
@onready var _visual: CanvasItem = %Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _contact_timer: float = 0.0
var _behavior_timer: float = 0.0
var _bursting: bool = false
var _strafe_sign: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	if stats == null:
		stats = EnemyStats.new()
	_apply_stats()
	_health.max_health = stats.max_health
	_health.current = stats.max_health
	_health.damaged.connect(_on_health_damaged)
	_health.depleted.connect(_on_health_depleted)
	_strafe_sign = -1.0 if randf() < 0.5 else 1.0


func _physics_process(delta: float) -> void:
	_contact_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var target_velocity := _get_target_velocity(player.global_position, delta)
		var weight := clampf(delta * stats.turn_speed, 0.0, 1.0)
		velocity = velocity.lerp(target_velocity, weight)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var c := col.get_collider()
		if c and c.is_in_group("player"):
			_try_damage_player(c as Node)


func _try_damage_player(player: Node) -> void:
	if _contact_timer > 0.0:
		return
	var h := player.get_node_or_null("Health") as Health
	if h:
		h.take_damage(stats.contact_damage)
	_contact_timer = stats.contact_cooldown


func _on_health_damaged(_amount: float) -> void:
	_visual.modulate = Color(1.0, 0.62, 0.62, 1.0)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", stats.visual_tint, 0.14)


func _on_health_depleted() -> void:
	var pickups := get_tree().get_first_node_in_group("pickups_root") as Node2D
	if pickups:
		var p := XP_PICKUP_SCENE.instantiate() as Node2D
		p.global_position = global_position
		p.set_meta("xp_amount", stats.xp_value)
		pickups.add_child(p)
	queue_free()


func _apply_stats() -> void:
	_visual.modulate = stats.visual_tint
	_visual.scale = Vector2.ONE * stats.visual_scale
	var circle := _collision.shape as CircleShape2D
	if circle:
		circle.radius = stats.collision_radius


func _get_target_velocity(player_position: Vector2, delta: float) -> Vector2:
	var to_player := global_position.direction_to(player_position)
	var distance := global_position.distance_to(player_position)
	match String(stats.behavior):
		"tank":
			var inertia := 0.85 if distance > 110.0 else 0.55
			return to_player * stats.speed * inertia
		"rusher":
			return _get_rusher_velocity(to_player, distance, delta)
		"elite":
			return _get_elite_velocity(to_player, distance, delta)
		_:
			return to_player * stats.speed


func _get_rusher_velocity(to_player: Vector2, distance: float, delta: float) -> Vector2:
	_behavior_timer -= delta
	if _behavior_timer <= 0.0:
		if _bursting:
			_bursting = false
			_behavior_timer = randf_range(0.7, 1.1)
		elif distance < 320.0 or randf() < 0.2:
			_bursting = true
			_behavior_timer = randf_range(0.38, 0.62)
		else:
			_behavior_timer = 0.16
	var side := to_player.orthogonal() * _strafe_sign * 0.25
	var direction := (to_player + side).normalized()
	var multiplier := stats.rush_speed_multiplier if _bursting else stats.recovery_speed_multiplier
	return direction * stats.speed * multiplier


func _get_elite_velocity(to_player: Vector2, distance: float, delta: float) -> Vector2:
	_behavior_timer -= delta
	if _behavior_timer <= 0.0:
		_bursting = not _bursting
		_behavior_timer = 0.8 if _bursting else 1.25
	var orbit := to_player.orthogonal() * _strafe_sign * stats.orbit_strength
	if distance > 240.0:
		orbit *= 0.45
	var direction := (to_player * 1.15 + orbit).normalized()
	var multiplier := stats.rush_speed_multiplier if _bursting else 1.0
	return direction * stats.speed * multiplier
