extends CharacterBody2D

const XP_PICKUP_SCENE := preload("res://scenes/xp_pickup.tscn")

@export var stats: EnemyStats
@onready var _health: Health = $Health
@onready var _visual: Polygon2D = $Polygon2D

var _contact_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	if stats == null:
		stats = EnemyStats.new()
	_health.max_health = stats.max_health
	_health.current = stats.max_health
	_health.damaged.connect(_on_health_damaged)
	_health.depleted.connect(_on_health_depleted)


func _physics_process(delta: float) -> void:
	_contact_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dir := global_position.direction_to(player.global_position)
		velocity = dir * stats.speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	for i in get_slide_collision_count():
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
	_visual.modulate = Color(1.0, 0.55, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.12)


func _on_health_depleted() -> void:
	var pickups := get_tree().get_first_node_in_group("pickups_root") as Node2D
	if pickups:
		var p := XP_PICKUP_SCENE.instantiate() as Node2D
		p.global_position = global_position
		p.set_meta("xp_amount", stats.xp_value)
		pickups.add_child(p)
	queue_free()
