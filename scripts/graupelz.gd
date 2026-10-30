class_name Graupelz
extends CharacterBody2D

## Das Lock-Monster: lockt Brummi mit Süßigkeiten an. Nur ein lautes NEIN macht es angreifbar.

signal defeated

enum State { LURE, STUNNED, FLEE }

const TEX_IDLE: Texture2D = preload("res://assets/monster/graupelz_idle.png")
const TEX_STUN: Texture2D = preload("res://assets/monster/graupelz_stunned.png")
const TEX_HURT: Texture2D = preload("res://assets/monster/graupelz_hurt.png")
const TEX_FLEE: Texture2D = preload("res://assets/monster/graupelz_flee.png")
const CANDY: Texture2D = preload("res://assets/items/lollipop.png")
const LURE_LINES := [
	"Na, kleiner Bär? Komm mit!",
	"Ich hab ganz viele Bonbons für dich!",
	"Psst … das bleibt unser Geheimnis!",
	"Komm, ich zeig dir was Tolles!",
]
const LURE_RANGE := 720.0
const STUN_TIME := 3.2
const HEIGHT := 300.0

## Bei false ist es nur eine kurze Begegnung: ein NEIN vertreibt das Monster sofort.
var boss := true
var max_hp := 3
var lines: Array = LURE_LINES
var tex_idle: Texture2D = TEX_IDLE
## Was in der Gedankenblase lockt (null = keine Blase)
var bait: Texture2D = CANDY

var hp := 3
var state := State.LURE
var _t := 0.0
var _state_t := 0.0
var _line := 0
var _hurt_t := 0.0
var _invuln := 0.0
var _origin := Vector2.ZERO
var _sprite: Sprite2D
var _bubble := StyleBoxFlat.new()
var _player: Brummi


func _ready() -> void:
	add_to_group("shout_listeners")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp
	_origin = position
	var shape := RectangleShape2D.new()
	shape.size = Vector2(150, 230)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -115)
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)
	_bubble.bg_color = Color(1, 1, 1, 0.95)
	_bubble.set_corner_radius_all(18)
	_bubble.border_color = Color("5b4a7a")
	_bubble.set_border_width_all(4)


func is_dangerous() -> bool:
	return state == State.LURE


func on_shout(_from: Node2D) -> void:
	if state != State.LURE:
		return
	if not boss:
		_say_and_vanish()
		return
	Sound.sfx("stun")
	_set_state(State.STUNNED)


func take_hit(_dir: int) -> void:
	if state != State.STUNNED or _invuln > 0.0:
		return
	hp -= 1
	_invuln = 0.5
	_hurt_t = 0.35
	velocity = Vector2(-_dir_to_player() * 520.0, -420.0)
	Sound.sfx("hit" if hp > 0 else "defeat", 0.0, 0.75)
	if hp <= 0:
		_set_state(State.FLEE)
		defeated.emit()
	else:
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if state == State.STUNNED:
				_set_state(State.LURE))


func _say_and_vanish() -> void:
	state = State.FLEE
	_line = -1
	collision_layer = 0
	Sound.sfx("vanish")
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)
	_poof()


func _poof() -> void:
	for i in 14:
		var puff := Node2D.new()
		var r := randf_range(18.0, 34.0)
		puff.draw.connect(func() -> void: puff.draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, r, r, 14), Color(0.6, 0.55, 0.7, 0.8)))
		puff.position = global_position + Vector2(randf_range(-60, 60), randf_range(-220, -40))
		get_parent().add_child(puff)
		var tw := puff.create_tween().set_parallel()
		tw.tween_property(puff, "position", puff.position + Vector2.from_angle(randf() * TAU) * 120.0, 0.7)
		tw.tween_property(puff, "modulate:a", 0.0, 0.7)
		tw.chain().tween_callback(puff.queue_free)


func _set_state(s: State) -> void:
	state = s
	_state_t = 0.0
	if s == State.FLEE:
		collision_layer = 0
		_poof()


func _dir_to_player() -> float:
	if _player == null:
		return -1.0
	return signf(_player.global_position.x - global_position.x)


func _physics_process(delta: float) -> void:
	_t += delta
	_state_t += delta
	_hurt_t = maxf(_hurt_t - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Brummi

	if not is_on_floor():
		velocity.y += 2400.0 * delta
	velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)

	match state:
		State.LURE:
			if _player and _player.controls_enabled:
				var d := _player.global_position - global_position
				if absf(d.x) < LURE_RANGE and absf(d.y) < 260.0:
					# Der Sog wird stärker, je näher Brummi kommt
					var k := 1.0 - absf(d.x) / LURE_RANGE
					_player.lure_pull = -signf(d.x) * (160.0 + 260.0 * k)
			position.x = move_toward(position.x, _origin.x, 120.0 * delta)
			if int(_t / 2.6) != _line:
				_line = int(_t / 2.6)
		State.STUNNED:
			if _state_t > STUN_TIME:
				_set_state(State.LURE)
		State.FLEE:
			if boss:
				velocity.x = 700.0
				if _state_t > 2.5:
					queue_free()

	move_and_slide()
	_update_sprite()
	queue_redraw()


func player_is_lured() -> bool:
	if state != State.LURE or _player == null:
		return false
	var d := _player.global_position - global_position
	return absf(d.x) < LURE_RANGE and absf(d.y) < 260.0


func _update_sprite() -> void:
	var tex := tex_idle
	match state:
		State.STUNNED:
			tex = TEX_HURT if _hurt_t > 0.0 else TEX_STUN
		State.FLEE:
			tex = TEX_FLEE if boss else TEX_STUN
	_sprite.texture = tex
	var s := HEIGHT / tex.get_height()
	var sway := sin(_t * 2.0) * 0.03 if state == State.LURE else 0.0
	_sprite.scale = Vector2(s * (1.0 + sway), s * (1.0 - sway))
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_sprite.flip_h = _dir_to_player() > 0.0 if state != State.FLEE else true
	_sprite.modulate = Color(2.0, 1.6, 1.6) if _hurt_t > 0.15 else Color.WHITE


func _draw() -> void:
	if state == State.LURE:
		Shapes.glow(self, Vector2(0, -HEIGHT * 0.5), 260.0, Color(0.6, 0.3, 0.9, 0.18 + 0.06 * sin(_t * 3.0)), 6)
		if bait:
			# Gedankenblase mit dem Köder
			var c := Vector2(-_dir_to_player() * 40.0, -HEIGHT - 80.0 + sin(_t * 2.0) * 6.0)
			draw_circle(c + Vector2(_dir_to_player() * 70.0, 60.0), 9.0, Color(1, 1, 1, 0.9))
			draw_circle(c + Vector2(_dir_to_player() * 50.0, 38.0), 14.0, Color(1, 1, 1, 0.9))
			draw_colored_polygon(Shapes.ellipse(c, 62.0, 52.0, 24), Color(1, 1, 1, 0.92))
			var cs := 88.0 / bait.get_height()
			draw_texture_rect(bait, Rect2(c - Vector2(bait.get_width() * cs, 88.0) * 0.5, Vector2(bait.get_width() * cs, 88.0)), false)
		if player_is_lured():
			_draw_speech(lines[_line % lines.size()])
	elif state == State.STUNNED:
		for i in 4:
			var a := _t * 4.0 + i * TAU / 4.0
			var p := Vector2(cos(a) * 70.0, -HEIGHT - 10.0 + sin(a) * 18.0)
			Shapes.glow(self, p, 16.0, Color(1.0, 0.9, 0.3, 0.9), 3)
		var left := STUN_TIME - _state_t
		draw_arc(Vector2(0, -HEIGHT - 60.0), 26.0, -PI / 2, -PI / 2 + TAU * left / STUN_TIME, 32, Color(1.0, 0.85, 0.3), 6.0)
	elif state == State.FLEE and not boss:
		_draw_speech("Grrr … ein NEIN! Ich verschwinde!")


func _draw_speech(text: String) -> void:
	var font := ThemeDB.fallback_font
	var size := 28
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var r := Rect2(Vector2(-ts.x * 0.5 - 18.0, -HEIGHT - 210.0), ts + Vector2(36, 24))
	draw_style_box(_bubble, r)
	draw_string(font, r.position + Vector2(18, 12 + font.get_ascent(size)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("3a2a55"))
