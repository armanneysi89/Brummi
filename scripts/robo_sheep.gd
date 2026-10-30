class_name RoboSheep
extends CharacterBody2D

signal defeated(pos: Vector2)

const GRAVITY := 2400.0
const SPRITE_SCALE := 0.75

@export var max_hp := 2
@export var patrol_range := 200.0
@export var speed := 110.0
@export var size := 1.0

var hp := 2
var _origin_x := 0.0
var _dir := -1
var _flash := 0.0
var _invuln := 0.0
var _stun := 0.0
var _t := 0.0
var _dead := false
var _sprite: Sprite2D
var _eye: Node2D
var _tex_idle: Texture2D = preload("res://assets/enemy/sheep_ref.png")
var _tex_walk: Texture2D = preload("res://assets/enemy/sheep_walk.png")
var _tex_hit: Texture2D = preload("res://assets/enemy/sheep_hit.png")


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("shout_listeners")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp
	_origin_x = global_position.x
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80.0, 70.0) * size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0.0, -35.0 * size)
	add_child(cs)

	_eye = Node2D.new()
	_eye.draw.connect(func() -> void:
		Shapes.glow(_eye, Vector2(0.0, -50.0 * size), 70.0 * size, Color(0.3, 0.9, 1.0, 0.18 + 0.08 * sin(_t * 4.0)), 5))
	add_child(_eye)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)


func is_dangerous() -> bool:
	return not _dead and _stun <= 0.0


func on_shout(player: Node2D) -> void:
	take_hit(1 if global_position.x > player.global_position.x else -1)


func take_hit(from_dir: int) -> void:
	if _dead or _invuln > 0.0:
		return
	hp -= 1
	_invuln = 0.4
	_flash = 0.12
	_stun = 0.45
	velocity = Vector2(from_dir * 420.0, -380.0)
	Sound.sfx("hit" if hp > 0 else "pop")
	if hp <= 0:
		_die()


func _die() -> void:
	_dead = true
	collision_layer = 0
	remove_from_group("enemies")
	defeated.emit(global_position)
	for i in 12:
		var puff := Node2D.new()
		var r := randf_range(10.0, 22.0) * size
		puff.draw.connect(func() -> void: puff.draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r, 14), Color(1, 1, 1, 0.95)))
		puff.position = global_position + Vector2(0, -40.0 * size)
		get_parent().add_child(puff)
		var tw := puff.create_tween().set_parallel()
		tw.tween_property(puff, "position", puff.position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 140.0) * size, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(puff, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(puff.queue_free)
	var fade := create_tween().set_parallel()
	fade.tween_property(self, "scale", Vector2(1.4, 0.2), 0.2)
	fade.tween_property(self, "modulate:a", 0.0, 0.2)
	fade.chain().tween_callback(queue_free)


func _ground_ahead() -> bool:
	var from := global_position + Vector2(_dir * 50.0 * size, -10.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 60.0), 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	var tex := _tex_hit if _stun > 0.0 else (_tex_walk if int(_t * 6.0) % 2 == 0 else _tex_idle)
	_sprite.texture = tex
	_sprite.flip_h = _dir > 0
	var s := SPRITE_SCALE * size
	var squash := 1.0 + absf(sin(_t * 12.0)) * 0.04
	_sprite.scale = Vector2(s / squash, s * squash)
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE
	_eye.queue_redraw()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_invuln = maxf(_invuln - delta, 0.0)
	_stun = maxf(_stun - delta, 0.0)

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if _stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var chasing := false
		if player and absf(player.global_position.x - global_position.x) < 420.0 \
				and absf(player.global_position.y - global_position.y) < 160.0:
			_dir = 1 if player.global_position.x > global_position.x else -1
			chasing = true
		elif global_position.x > _origin_x + patrol_range:
			_dir = -1
		elif global_position.x < _origin_x - patrol_range:
			_dir = 1
		if is_on_wall():
			_dir = -_dir
		var blocked := is_on_floor() and not _ground_ahead()
		if blocked and not chasing:
			_dir = -_dir
		velocity.x = 0.0 if blocked and chasing else _dir * speed * (1.7 if chasing else 1.0)

	move_and_slide()
