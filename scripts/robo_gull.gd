class_name RoboGull
extends CharacterBody2D

## Fliegende Robo-Möwe: kreist über dem Weg und stößt auf Brummi herab. Mit Herzen gut zu treffen.

const TEX_FLY: Texture2D = preload("res://assets/enemy/gull_ref.png")
const TEX_FLAP: Texture2D = preload("res://assets/enemy/gull_fly.png")
const TEX_HAPPY: Texture2D = preload("res://assets/enemy/gull_happy.png")
const HEIGHT := 90.0
const DIVE_SPEED := 520.0

var patrol_range := 260.0
var speed := 150.0

var _origin := Vector2.ZERO
var _dir := -1
var _t := 0.0
var _flash := 0.0
var _dive := 0.0
var _dive_cd := 1.5
var _happy := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("shout_listeners")
	collision_layer = 4
	collision_mask = 0
	_origin = position
	var shape := CircleShape2D.new()
	shape.radius = 36.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -HEIGHT * 0.5)
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)


func is_dangerous() -> bool:
	return not _happy


func on_shout(player: Node2D) -> void:
	take_hit(1 if global_position.x > player.global_position.x else -1)


func take_hit(_from_dir: int) -> void:
	if _happy:
		return
	_happy = true
	_flash = 0.12
	collision_layer = 0
	remove_from_group("enemies")
	Sound.sfx("befriend")
	HeartShot.burst(get_parent(), global_position + Vector2(0, -HEIGHT * 0.5), 8)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position", position + Vector2(-_dir * 300.0, -700.0), 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(1.4)
	tw.chain().tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	if not _happy:
		_fly(delta)
	_sprite.texture = TEX_HAPPY if _happy else (TEX_FLAP if int(_t * 5.0) % 2 == 0 else TEX_FLY)
	var s := HEIGHT / _sprite.texture.get_height()
	_sprite.scale = Vector2(s, s)
	_sprite.position = Vector2(0, -HEIGHT * 0.5)
	_sprite.flip_h = _dir > 0
	_sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE


func _fly(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_dive_cd -= delta
	if _dive > 0.0:
		_dive -= delta
		# Erst herab zum Spieler, dann wieder hinauf
		var up := _dive < 0.6
		velocity = Vector2(_dir * DIVE_SPEED * 0.6, -DIVE_SPEED * 0.8 if up else DIVE_SPEED)
		if player and not up and global_position.y > player.global_position.y - 40.0:
			_dive = 0.6
	else:
		if position.x > _origin.x + patrol_range:
			_dir = -1
		elif position.x < _origin.x - patrol_range:
			_dir = 1
		velocity = Vector2(_dir * speed, (_origin.y + sin(_t * 2.5) * 30.0 - position.y) * 4.0)
		if player and _dive_cd <= 0.0:
			var d := player.global_position - global_position
			if absf(d.x) < 300.0 and d.y > 80.0 and d.y < 520.0 and signf(d.x) == _dir:
				_dive = 0.6 + d.y / DIVE_SPEED
				_dive_cd = 3.0
	move_and_slide()
