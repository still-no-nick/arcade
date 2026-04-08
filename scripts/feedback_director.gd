extends Node

const PROJECTILE_TEXTURE := preload("res://assets/sprites/projectile_bolt.svg")
const XP_TEXTURE := preload("res://assets/sprites/xp_core.svg")
const SAMPLE_RATE := 22050
const SOUND_EVENTS := [
	"shot",
	"hit",
	"hit_crit",
	"xp",
	"enemy_death",
	"player_hurt",
	"player_death",
	"level_up",
	"upgrade",
]

var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var _camera_base_offset: Vector2 = Vector2.ZERO
var _shake_trauma: float = 0.0
var _world_layer: Node2D
var _overlay_layer: CanvasLayer
var _overlay_rect: ColorRect
var _sound_streams: Dictionary = {}


func _ready() -> void:
	add_to_group("feedback")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_world_layer = Node2D.new()
	_world_layer.name = "WorldFeedback"
	add_child(_world_layer)
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "OverlayFeedback"
	_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_layer)
	_overlay_rect = ColorRect.new()
	_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_overlay_layer.add_child(_overlay_rect)
	_prewarm_sound_streams()
	GameState.level_up_choices.connect(_on_level_up_choices)
	GameState.player_died.connect(_on_player_died)
	await get_tree().process_frame
	_cache_camera()


func _process(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_cache_camera()
	if _camera == null:
		return
	_shake_trauma = maxf(_shake_trauma - delta * 2.6, 0.0)
	var shake_power := _shake_trauma * _shake_trauma
	if shake_power <= 0.0:
		_camera.offset = _camera.offset.lerp(_camera_base_offset, minf(1.0, delta * 16.0))
		return
	var strength := 20.0 * shake_power
	_camera.offset = _camera_base_offset + Vector2(
		_rng.randf_range(-strength, strength),
		_rng.randf_range(-strength, strength)
	)


func play_shot(origin: Vector2, direction: Vector2, projectile_count: int = 1) -> void:
	var color := Color("78d8ff")
	_spawn_streak_burst(origin + direction * 18.0, color, 4 + projectile_count, 14.0, 30.0, 2.8, 0.14)
	_spawn_glow(origin + direction * 22.0, PROJECTILE_TEXTURE, color, Vector2.ONE * 0.34, Vector2.ONE * 0.8, 0.12)
	_add_shake(0.08 + 0.015 * float(projectile_count - 1))
	_play_sound("shot")


func play_hit(position: Vector2, damage: float, is_crit: bool = false) -> void:
	var color := Color("ffd45a") if is_crit else Color("ff8a7a")
	_spawn_streak_burst(position, color, 5 if is_crit else 3, 10.0, 22.0, 2.4, 0.12)
	_spawn_ring(position, color, 10.0, 34.0 if is_crit else 24.0, 3.0, 0.16)
	_add_shake(0.06 if is_crit else 0.03)
	if is_crit:
		_flash(Color(1.0, 0.84, 0.4, 0.16), 0.11)
	_play_sound("hit_crit" if is_crit else "hit", clampf(-13.0 + damage * 0.08, -13.0, -7.0))


func play_enemy_death(position: Vector2, tint: Color) -> void:
	_spawn_streak_burst(position, tint.lightened(0.3), 8, 18.0, 48.0, 3.2, 0.22)
	_spawn_ring(position, tint.lightened(0.5), 14.0, 58.0, 4.0, 0.24)
	_spawn_glow(position, PROJECTILE_TEXTURE, tint.lightened(0.45), Vector2.ONE * 0.45, Vector2.ONE * 1.8, 0.2)
	_add_shake(0.12)
	_play_sound("enemy_death", -9.0)


func play_xp_pickup(position: Vector2, xp_amount: int) -> void:
	var color := Color("6dffe8")
	_spawn_streak_burst(position, color, int(mini(6, 2 + xp_amount / 2)), 8.0, 24.0, 2.2, 0.14)
	_spawn_glow(position, XP_TEXTURE, color, Vector2.ONE * 0.22, Vector2.ONE * 0.9, 0.18)
	_play_sound("xp", clampf(-12.0 + xp_amount * 0.15, -12.0, -6.0))


func play_player_hurt(position: Vector2) -> void:
	_spawn_ring(position, Color("ff6a7a"), 12.0, 42.0, 3.0, 0.18)
	_flash(Color(1.0, 0.2, 0.24, 0.18), 0.12)
	_add_shake(0.16)
	_play_sound("player_hurt", -8.0)


func play_player_death(position: Vector2) -> void:
	_spawn_streak_burst(position, Color("ff6f8f"), 12, 22.0, 62.0, 3.8, 0.32)
	_spawn_ring(position, Color("ffd5dd"), 20.0, 110.0, 6.0, 0.38)
	_flash(Color(0.95, 0.12, 0.2, 0.34), 0.28)
	_add_shake(0.42)
	_play_sound("player_death", -5.0)


func play_upgrade_pick(position: Vector2) -> void:
	_spawn_ring(position, Color("82f3ff"), 16.0, 82.0, 5.0, 0.3)
	_spawn_streak_burst(position, Color("c7fcff"), 9, 20.0, 54.0, 3.0, 0.22)
	_flash(Color(0.45, 0.95, 1.0, 0.18), 0.16)
	_add_shake(0.18)
	_play_sound("upgrade", -6.0)


func _on_level_up_choices(_new_level: int, _choices: Array) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	_spawn_ring(player.global_position, Color("f8ff95"), 24.0, 134.0, 8.0, 0.42)
	_spawn_streak_burst(player.global_position, Color("fff0a7"), 14, 26.0, 88.0, 4.4, 0.34)
	_spawn_glow(player.global_position, XP_TEXTURE, Color("fff3ae"), Vector2.ONE * 0.45, Vector2.ONE * 2.5, 0.36)
	_flash(Color(1.0, 0.94, 0.58, 0.22), 0.18)
	_add_shake(0.22)
	_play_sound("level_up", -5.0)


func _on_player_died() -> void:
	_flash(Color(0.34, 0.0, 0.04, 0.28), 0.24)


func _cache_camera() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	_camera = player.get_node_or_null("Camera2D") as Camera2D
	if _camera:
		_camera_base_offset = _camera.offset


func _add_shake(amount: float) -> void:
	_shake_trauma = clampf(_shake_trauma + amount, 0.0, 1.0)


func _flash(color: Color, duration: float) -> void:
	_overlay_rect.color = Color(color.r, color.g, color.b, 0.0)
	var tween := create_tween()
	tween.tween_property(_overlay_rect, "color", color, duration * 0.28)
	tween.tween_property(_overlay_rect, "color", Color(color.r, color.g, color.b, 0.0), duration * 0.72)


func _spawn_glow(position: Vector2, texture: Texture2D, color: Color, from_scale: Vector2, to_scale: Vector2, duration: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.modulate = color
	sprite.scale = from_scale
	_world_layer.add_child(sprite)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", to_scale, duration)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, duration)
	tween.finished.connect(sprite.queue_free)


func _spawn_streak_burst(position: Vector2, color: Color, count: int, min_length: float, max_length: float, width: float, duration: float) -> void:
	var root := Node2D.new()
	root.position = position
	root.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_world_layer.add_child(root)
	for _i in range(count):
		var line := Line2D.new()
		line.default_color = color
		line.width = width * _rng.randf_range(0.7, 1.15)
		line.antialiased = true
		var angle := _rng.randf_range(0.0, TAU)
		var length := _rng.randf_range(min_length, max_length)
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.RIGHT.rotated(angle) * length)
		root.add_child(line)
	var tween := create_tween()
	tween.tween_property(root, "scale", Vector2.ONE * 1.18, duration)
	tween.parallel().tween_property(root, "modulate:a", 0.0, duration)
	tween.finished.connect(root.queue_free)


func _spawn_ring(position: Vector2, color: Color, start_radius: float, end_radius: float, width: float, duration: float) -> void:
	var ring := Line2D.new()
	ring.default_color = color
	ring.width = width
	ring.closed = true
	ring.antialiased = true
	var points := 28
	for i in range(points):
		var angle := TAU * float(i) / float(points)
		ring.add_point(Vector2.RIGHT.rotated(angle) * start_radius)
	ring.position = position
	_world_layer.add_child(ring)
	var scale_factor := end_radius / maxf(start_radius, 1.0)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * scale_factor, duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(ring.queue_free)


func _play_sound(event_name: String, volume_db: float = -8.0) -> void:
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = _sound_streams.get(event_name)
	if player.stream == null:
		player.stream = _build_sound_stream(event_name)
		_sound_streams[event_name] = player.stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _prewarm_sound_streams() -> void:
	for event_name in SOUND_EVENTS:
		_sound_streams[event_name] = _build_sound_stream(event_name)


func _build_sound_stream(event_name: String) -> AudioStreamWAV:
	var settings := {
		"segments": [
			{"duration": 0.09, "from": 520.0, "to": 340.0, "wave": "triangle", "amp": 0.55, "noise": 0.02},
		]
	}
	match event_name:
		"shot":
			settings = {
				"segments": [
					{"duration": 0.06, "from": 920.0, "to": 520.0, "wave": "triangle", "amp": 0.42, "noise": 0.06},
				]
			}
		"hit":
			settings = {
				"segments": [
					{"duration": 0.05, "from": 360.0, "to": 190.0, "wave": "square", "amp": 0.36, "noise": 0.14},
				]
			}
		"hit_crit":
			settings = {
				"segments": [
					{"duration": 0.04, "from": 560.0, "to": 320.0, "wave": "square", "amp": 0.42, "noise": 0.18},
					{"duration": 0.06, "from": 840.0, "to": 420.0, "wave": "triangle", "amp": 0.28, "noise": 0.02},
				]
			}
		"xp":
			settings = {
				"segments": [
					{"duration": 0.05, "from": 880.0, "to": 1060.0, "wave": "sine", "amp": 0.26, "noise": 0.0},
					{"duration": 0.05, "from": 1060.0, "to": 1320.0, "wave": "sine", "amp": 0.22, "noise": 0.0},
				]
			}
		"enemy_death":
			settings = {
				"segments": [
					{"duration": 0.08, "from": 280.0, "to": 180.0, "wave": "triangle", "amp": 0.36, "noise": 0.22},
					{"duration": 0.11, "from": 180.0, "to": 80.0, "wave": "saw", "amp": 0.28, "noise": 0.28},
				]
			}
		"player_hurt":
			settings = {
				"segments": [
					{"duration": 0.08, "from": 240.0, "to": 120.0, "wave": "saw", "amp": 0.42, "noise": 0.16},
				]
			}
		"player_death":
			settings = {
				"segments": [
					{"duration": 0.12, "from": 220.0, "to": 90.0, "wave": "saw", "amp": 0.48, "noise": 0.26},
					{"duration": 0.18, "from": 90.0, "to": 36.0, "wave": "noise", "amp": 0.3, "noise": 0.45},
				]
			}
		"level_up":
			settings = {
				"segments": [
					{"duration": 0.08, "from": 520.0, "to": 720.0, "wave": "triangle", "amp": 0.26, "noise": 0.0},
					{"duration": 0.08, "from": 780.0, "to": 1020.0, "wave": "triangle", "amp": 0.28, "noise": 0.0},
					{"duration": 0.09, "from": 1080.0, "to": 1440.0, "wave": "sine", "amp": 0.24, "noise": 0.0},
				]
			}
		"upgrade":
			settings = {
				"segments": [
					{"duration": 0.06, "from": 660.0, "to": 760.0, "wave": "triangle", "amp": 0.22, "noise": 0.0},
					{"duration": 0.06, "from": 880.0, "to": 980.0, "wave": "triangle", "amp": 0.22, "noise": 0.0},
					{"duration": 0.08, "from": 1180.0, "to": 1380.0, "wave": "sine", "amp": 0.24, "noise": 0.0},
				]
			}
	return _build_pcm_stream(settings["segments"])


func _build_pcm_stream(segments: Array) -> AudioStreamWAV:
	var total_samples := 0
	for segment in segments:
		total_samples += maxi(1, int(round(SAMPLE_RATE * float(segment["duration"]))))
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	var write_index := 0
	var phase := 0.0
	for segment in segments:
		var segment_samples := maxi(1, int(round(SAMPLE_RATE * float(segment["duration"]))))
		for i in range(segment_samples):
			var t := float(i) / float(maxi(segment_samples - 1, 1))
			var frequency := lerpf(float(segment["from"]), float(segment["to"]), t)
			phase += TAU * frequency / float(SAMPLE_RATE)
			var env := sin(t * PI)
			env = pow(env, 0.82)
			var sample := _wave_sample(phase, String(segment["wave"]))
			var noise := float(segment["noise"])
			if noise > 0.0:
				sample = lerpf(sample, _rng.randf_range(-1.0, 1.0), noise)
			sample *= float(segment["amp"]) * env
			var pcm := int(round(clampf(sample, -1.0, 1.0) * 32767.0))
			bytes[write_index] = pcm & 0xff
			bytes[write_index + 1] = (pcm >> 8) & 0xff
			write_index += 2
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _wave_sample(phase: float, waveform: String) -> float:
	match waveform:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"triangle":
			return asin(sin(phase)) * (2.0 / PI)
		"saw":
			return fmod(phase / PI + 1.0, 2.0) - 1.0
		"noise":
			return _rng.randf_range(-1.0, 1.0)
		_:
			return sin(phase)
