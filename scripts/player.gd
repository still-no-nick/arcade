extends CharacterBody2D

@export var weapon_stats: WeaponStats
@export var move_speed: float = 240.0

@onready var _health: Health = $Health
@onready var _visual: CanvasItem = %Visual


func _ready() -> void:
	add_to_group("player")
	if weapon_stats == null:
		weapon_stats = WeaponStats.new()
	_health.damaged.connect(_on_health_damaged)
	_health.depleted.connect(_on_health_depleted)


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * move_speed
	move_and_slide()


func apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return
	match String(upgrade.stat):
		"damage":
			weapon_stats.damage = weapon_stats.damage * upgrade.multiplier + upgrade.additive
		"fire_rate":
			weapon_stats.fire_rate = weapon_stats.fire_rate * upgrade.multiplier + upgrade.additive
		"move_speed":
			move_speed = move_speed * upgrade.multiplier + upgrade.additive
		"max_health":
			_health.max_health += upgrade.additive
			_health.heal(upgrade.additive)
	var w := get_node_or_null("AutoWeapon")
	if w and w.has_method("update_fire_rate"):
		w.update_fire_rate()


func _on_health_damaged(_amount: float) -> void:
	_visual.modulate = Color(1.0, 0.55, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.18)


func _on_health_depleted() -> void:
	GameState.notify_player_died()
