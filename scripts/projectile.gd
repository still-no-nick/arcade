extends Area2D

@export var max_lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var pierce_left: int = 0
var is_crit: bool = false
var _lifetime_left: float = 0.0
@onready var _visual: CanvasItem = $Sprite2D


func _ready() -> void:
	_lifetime_left = max_lifetime
	body_entered.connect(_on_body_entered)
	rotation = velocity.angle()
	if is_crit:
		_visual.modulate = Color(1.0, 0.92, 0.48, 1.0)
		_visual.scale *= 1.18


func _physics_process(delta: float) -> void:
	_lifetime_left -= delta
	if _lifetime_left <= 0.0:
		queue_free()
		return
	global_position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return
	if not body.is_in_group("enemies"):
		return
	var h := body.get_node_or_null("Health") as Health
	if h:
		h.take_damage(damage)
	if pierce_left > 0:
		pierce_left -= 1
		return
	queue_free()
