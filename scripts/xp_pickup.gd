extends Area2D

const FeedbackHelper := preload("res://scripts/helpers/feedback_helper.gd")

var xp_amount: int = 5
@export var attraction_speed: float = 460.0
var _player: Node2D
var _pickup_radius_provider: Node
var _bob_time: float = 0.0
@onready var _sprite: Sprite2D = $Sprite2D
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	if has_meta("xp_amount"):
		xp_amount = int(get_meta("xp_amount"))
	body_entered.connect(_on_body_entered)
	_base_scale = _sprite.scale
	_cache_player()


func _cache_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_pickup_radius_provider = _player
	if _player == null:
		await get_tree().process_frame
		_player = get_tree().get_first_node_in_group("player") as Node2D
		_pickup_radius_provider = _player


func _physics_process(delta: float) -> void:
	_bob_time += delta
	_sprite.scale = _base_scale * (1.0 + 0.08 * sin(_bob_time * 6.5))
	_sprite.rotation = sin(_bob_time * 4.0) * 0.08
	if _player == null or not is_instance_valid(_player):
		_cache_player()
	if _player == null:
		return
	var radius := 0.0
	if _pickup_radius_provider and _pickup_radius_provider.has_method("get_pickup_radius"):
		radius = float(_pickup_radius_provider.call("get_pickup_radius"))
	var distance := global_position.distance_to(_player.global_position)
	if distance > radius:
		return
	var strength := clampf(1.0 - distance / maxf(radius, 1.0), 0.15, 1.0)
	global_position = global_position.move_toward(_player.global_position, attraction_speed * strength * delta)


func _on_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		var feedback := FeedbackHelper.get_feedback(self)
		if feedback and feedback.has_method("play_xp_pickup"):
			feedback.play_xp_pickup(global_position, xp_amount)
		GameState.add_xp(xp_amount)
		queue_free()
