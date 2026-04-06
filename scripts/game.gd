extends Node2D

@onready var _player: CharacterBody2D = $Player


func _ready() -> void:
	add_to_group("game_root")
	GameState.reset_match()
	GameState.player_died.connect(_on_player_died)
	get_tree().paused = false


func _process(delta: float) -> void:
	if GameState.match_active and not get_tree().paused:
		GameState.survival_time += delta


func apply_upgrade(upgrade: UpgradeData) -> void:
	if _player and _player.has_method("apply_upgrade"):
		_player.apply_upgrade(upgrade)
	if upgrade != null:
		GameState.upgrade_chosen(String(upgrade.id))


func _on_player_died() -> void:
	get_tree().paused = true
	var p := $UI/GameOverPanel
	if p and p.has_method("show_panel"):
		p.show_panel()
