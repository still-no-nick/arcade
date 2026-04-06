extends Area2D

@export var max_lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var _lifetime_left: float = 0.0


func _ready() -> void:
	_lifetime_left = max_lifetime
	body_entered.connect(_on_body_entered)


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
	queue_free()
