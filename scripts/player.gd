class_name Brummi
extends CharacterBody2D

signal health_changed(hp: int)
signal shouted

const MAX_HP := 3
const SPEED := 480.0
const ACCEL := 3400.0
const FRICTION := 3800.0
const GRAVITY := 2400.0
const JUMP_VELOCITY := -960.0
const MAX_FALL := 1500.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const DASH_SPEED := 1150.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.6
const PUNCH_TIME := 0.28
const INVULN_TIME := 1.2
const FALL_LIMIT := 1500.0
const SHOUT_TIME := 0.5
const SHOUT_COOLDOWN := 1.0
const SHOUT_RADIUS := 560.0
const SPRITE_SCALE := 0.7
const RUN_CYCLE := ["run1", "run2", "run3", "run2"]
# Horizontaler Ankerpunkt (Anteil der Bildbreite), wo der Körper sitzt
const ANCHOR_X := {"punch": 0.36, "dash": 0.55}

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE, KEY_W, KEY_UP],
	"punch": [KEY_J, KEY_X],
	"dash": [KEY_K, KEY_SHIFT],
	"shout": [KEY_E, KEY_N, KEY_L],
	"restart": [KEY_R],
	"advance": [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER],
	"skip": [KEY_ESCAPE],
}

var hp := MAX_HP
var facing := 1
var spawn_point := Vector2.ZERO
var controls_enabled := true
var celebrating := false
# Wird von Monstern pro Frame gesetzt, die Brummi zu sich locken
var lure_pull := 0.0

var _shout_t := 0.0
var _shout_cd := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _punch_t := 0.0
var _invuln := 0.0
var _stun_t := 0.0
var _anim_t := 0.0
var _ghost_t := 0.0
var _was_on_floor := true
var _squash := Vector2.ONE
var _frames := {}
var _frame := ""
var _sprite: Sprite2D
var _fx: Node2D
var _hitbox: Area2D
var _hurtbox: Area2D


static func ensure_input_actions() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _ready() -> void:
	ensure_input_actions()
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

	for f in ["idle", "run1", "run2", "run3", "jump", "fall", "punch", "dash", "hurt", "victory", "special"]:
		_frames[f] = load("res://assets/brummi/bear_%s.png" % f)

	var shadow := Sprite2D.new()
	shadow.texture = _shadow_texture()
	shadow.scale = Vector2(1.0, 0.25)
	shadow.modulate = Color(0, 0, 0, 0.3)
	add_child(shadow)

	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_set_frame("idle")

	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(60, 110)
	var cs := CollisionShape2D.new()
	cs.shape = body_shape
	cs.position = Vector2(0, -55)
	add_child(cs)

	var hit_shape := CircleShape2D.new()
	hit_shape.radius = 56.0
	_hitbox = _make_area(hit_shape, Vector2(80, -60))
	var hurt_shape := RectangleShape2D.new()
	hurt_shape.size = Vector2(52, 96)
	_hurtbox = _make_area(hurt_shape, Vector2(0, -55))


func _shadow_texture() -> Texture2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 96
	tex.height = 96
	return tex


func _make_area(shape: Shape2D, pos: Vector2) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 4
	var cs := CollisionShape2D.new()
	cs.shape = shape
	area.add_child(cs)
	area.position = pos
	add_child(area)
	return area


func _physics_process(delta: float) -> void:
	_anim_t += delta
	_invuln = maxf(_invuln - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_punch_t = maxf(_punch_t - delta, 0.0)
	_stun_t = maxf(_stun_t - delta, 0.0)
	_shout_t = maxf(_shout_t - delta, 0.0)
	_shout_cd = maxf(_shout_cd - delta, 0.0)

	var dir := 0.0
	if controls_enabled and _stun_t <= 0.0:
		dir = Input.get_axis("move_left", "move_right")
	if dir != 0.0 and _punch_t <= 0.0 and _dash_t <= 0.0:
		facing = 1 if dir > 0.0 else -1

	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote -= delta
	_jump_buffer -= delta

	if controls_enabled:
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = JUMP_BUFFER
		if Input.is_action_just_pressed("punch") and _punch_t <= 0.0:
			_punch_t = PUNCH_TIME
		if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and _stun_t <= 0.0:
			_dash_t = DASH_TIME
			_dash_cd = DASH_COOLDOWN
		if Input.is_action_just_pressed("shout") and _shout_cd <= 0.0:
			_shout()

	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = Vector2(facing * DASH_SPEED, 0.0)
	else:
		if not is_on_floor():
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		if _jump_buffer > 0.0 and _coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			_jump_buffer = 0.0
			_coyote = 0.0
			_squash = Vector2(0.82, 1.18)
		if controls_enabled and Input.is_action_just_released("jump") and velocity.y < -250.0:
			velocity.y *= 0.5
		if _stun_t > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.25 * delta)
		else:
			var rate := ACCEL if dir != 0.0 else FRICTION
			velocity.x = move_toward(velocity.x, dir * SPEED, rate * delta)
		if _shout_t > 0.0 and is_on_floor():
			velocity.x = 0.0

	var pulled := velocity
	velocity.x += lure_pull
	move_and_slide()
	if lure_pull != 0.0:
		velocity.x = pulled.x
	lure_pull = 0.0
	if is_on_floor() and not _was_on_floor:
		_squash = Vector2(1.18, 0.84)
	_was_on_floor = is_on_floor()

	_hitbox.position.x = 80.0 * facing
	_check_attacks()
	_check_damage()

	if global_position.y > FALL_LIMIT:
		_fall_reset()

	_animate(delta)


func _animate(delta: float) -> void:
	var grounded := is_on_floor()
	var frame := "idle"
	if celebrating:
		frame = "victory"
	elif _stun_t > 0.0:
		frame = "hurt"
	elif _shout_t > 0.0:
		frame = "special"
	elif _dash_t > 0.0:
		frame = "dash"
	elif _punch_t > 0.0:
		frame = "punch"
	elif not grounded:
		frame = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 40.0:
		frame = RUN_CYCLE[int(_anim_t * 11.0) % RUN_CYCLE.size()]
	_set_frame(frame)

	_squash = _squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	var breathe := Vector2.ONE
	if frame == "idle":
		breathe = Vector2(1.0 - sin(_anim_t * 3.0) * 0.012, 1.0 + sin(_anim_t * 3.0) * 0.02)
	var bob := 0.0
	if celebrating:
		bob = -absf(sin(_anim_t * 6.0)) * 22.0
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE) * _squash * breathe
	_sprite.position.y = bob
	_sprite.flip_h = facing < 0
	var tex: Texture2D = _frames[_frame]
	var ax: float = ANCHOR_X.get(_frame, 0.5)
	if facing < 0:
		ax = 1.0 - ax
	_sprite.offset = Vector2(-tex.get_width() * ax, -tex.get_height())

	_sprite.modulate.a = 0.4 if _invuln > 0.0 and int(_invuln * 16.0) % 2 == 0 else 1.0
	if _dash_t > 0.0:
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = 0.03
			_spawn_ghost()
	_fx.queue_redraw()


func _shout() -> void:
	_shout_t = SHOUT_TIME
	_shout_cd = SHOUT_COOLDOWN
	shouted.emit()
	for node in get_tree().get_nodes_in_group("shout_listeners"):
		if node.global_position.distance_to(global_position) < SHOUT_RADIUS:
			node.on_shout(self)
	var label := Label.new()
	label.text = "NEIN!"
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color("ffe066"))
	label.add_theme_color_override("font_outline_color", Color("5a2a00"))
	label.add_theme_constant_override("outline_size", 14)
	label.position = global_position + Vector2(-80, -260)
	label.z_index = 20
	get_parent().add_child(label)
	var tw := label.create_tween().set_parallel()
	tw.tween_property(label, "position:y", label.position.y - 90.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(label.queue_free)


func hurt(away: float) -> void:
	if _invuln <= 0.0:
		_hurt(away)


func _set_frame(f: String) -> void:
	if f == _frame:
		return
	_frame = f
	_sprite.texture = _frames[f]


func _spawn_ghost() -> void:
	var g := Sprite2D.new()
	g.texture = _sprite.texture
	g.centered = false
	g.offset = _sprite.offset
	g.flip_h = _sprite.flip_h
	g.global_position = _sprite.global_position
	g.scale = _sprite.scale
	g.modulate = Color(1.0, 0.85, 0.35, 0.6)
	g.z_index = z_index - 1
	get_parent().add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)


func _draw_fx() -> void:
	if _shout_t > 0.0:
		var k := 1.0 - _shout_t / SHOUT_TIME
		Shapes.glow(_fx, Vector2(0, -70), 120.0 * (1.0 - k * 0.5), Color(1.0, 0.85, 0.3, 0.8 * (1.0 - k)), 6)
		for i in 3:
			var r := fmod(k + i / 3.0, 1.0) * SHOUT_RADIUS * 0.8
			_fx.draw_arc(Vector2(0, -70), r, 0.0, TAU, 48, Color(1.0, 0.9, 0.4, (1.0 - r / (SHOUT_RADIUS * 0.8)) * 0.9), 8.0)
	if _punch_t > 0.0:
		var ext := sin((1.0 - _punch_t / PUNCH_TIME) * PI)
		var fist := Vector2(facing * (62.0 + 24.0 * ext), -62.0)
		Shapes.glow(_fx, fist, 40.0 + 30.0 * ext, Color(1.0, 0.82, 0.25, 0.85), 6)
		for k in 8:
			var d := Vector2.from_angle(TAU * float(k) / 8.0 + _anim_t * 6.0)
			_fx.draw_line(fist + d * 22.0, fist + d * (32.0 + 26.0 * ext), Color(1.0, 0.95, 0.6, 0.9), 3.0)
		var arc_c := fist + Vector2(facing * 10.0, 0.0)
		var start := -PI * 0.5 if facing > 0 else PI * 0.5
		_fx.draw_arc(arc_c, 38.0 + 12.0 * ext, start, start + PI * float(facing), 16, Color(1.0, 0.9, 0.4, ext), 6.0)
	if _dash_t > 0.0:
		for i in 3:
			var y := -30.0 - i * 30.0
			_fx.draw_line(Vector2(-facing * 50.0, y), Vector2(-facing * (170.0 + i * 30.0), y), Color(1.0, 0.85, 0.35, 0.5), 6.0)


func _check_attacks() -> void:
	if _punch_t > 0.0 and _punch_t < PUNCH_TIME - 0.06:
		for body in _hitbox.get_overlapping_bodies():
			if body.has_method("take_hit"):
				body.take_hit(facing)
	if _dash_t > 0.0:
		for body in _hurtbox.get_overlapping_bodies():
			if body.has_method("take_hit"):
				body.take_hit(facing)


func _check_damage() -> void:
	if _invuln > 0.0 or _dash_t > 0.0 or celebrating:
		return
	for body in _hurtbox.get_overlapping_bodies():
		if body.has_method("is_dangerous") and body.is_dangerous():
			var away := signf(global_position.x - body.global_position.x)
			_hurt(away if away != 0.0 else -float(facing))
			return


func _hurt(away: float) -> void:
	hp -= 1
	_invuln = INVULN_TIME
	_stun_t = 0.35
	velocity = Vector2(away * 520.0, -520.0)
	health_changed.emit(hp)
	if hp <= 0:
		respawn()


func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	hp = MAX_HP
	_invuln = INVULN_TIME
	health_changed.emit(hp)


func _fall_reset() -> void:
	var remaining := hp - 1
	respawn()
	if remaining > 0:
		hp = remaining
		health_changed.emit(hp)
