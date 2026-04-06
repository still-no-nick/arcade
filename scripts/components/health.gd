class_name Health
extends Node

signal damaged(amount: float)
signal health_changed(current: float, max_health: float)
signal depleted

@export var max_health: float = 100.0
var current: float = 0.0


func _ready() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func reset_health() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	current -= amount
	damaged.emit(amount)
	if current <= 0.0:
		current = 0.0
	health_changed.emit(current, max_health)
	if current <= 0.0:
		depleted.emit()


func heal(amount: float) -> void:
	current = minf(current + amount, max_health)
	health_changed.emit(current, max_health)
