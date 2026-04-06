extends Area2D

var xp_amount: int = 5


func _ready() -> void:
	if has_meta("xp_amount"):
		xp_amount = int(get_meta("xp_amount"))
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		GameState.add_xp(xp_amount)
		queue_free()
