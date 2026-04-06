class_name EnemyStats
extends Resource

@export var id: StringName = &"chaser"
@export var display_name: String = "Chaser"
@export var behavior: StringName = &"chaser"
@export var max_health: float = 28.0
@export var speed: float = 95.0
@export var turn_speed: float = 7.0
@export var rush_speed_multiplier: float = 2.0
@export var recovery_speed_multiplier: float = 0.65
@export var orbit_strength: float = 0.0
@export var contact_damage: float = 8.0
@export var contact_cooldown: float = 0.55
@export var xp_value: int = 6
@export var visual_scale: float = 0.34
@export var collision_radius: float = 16.0
@export var visual_tint: Color = Color.WHITE
@export var is_elite: bool = false
