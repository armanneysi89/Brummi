class_name Anaja
extends Node2D

## Die kleine Füchsin: hat sich verlaufen, bringt Brummi den Herz-Wurf bei und läuft dann mit ihm zum Leuchtturm.

signal met

const TEX_SAD: Texture2D = preload("res://assets/characters/anaja_sad.png")
const TEX_IDLE: Texture2D = preload("res://assets/characters/anaja.png")
const TEX_RUN: Texture2D = preload("res://assets/characters/anaja_run.png")
const TEX_HAPPY: Texture2D = preload("res://assets/characters/anaja_happy.png")
const HEIGHT := 118.0
const MEET_RANGE := 150.0
const TIPS := [
	"Mama und ich haben ausgemacht: Wenn wir uns verlieren, treffen wir uns am Leuchtturm!",
	"Wirf Herzen mit L oder C – dann werden die Robo-Krabben wieder lieb!",
	"Die Möwen fliegen hoch oben. Ein Herz erreicht sie trotzdem!",
	"Ich weiß, wie ich heiße und wo ich wohne. Das hilft, wenn man sich verlaufen hat.",
]

enum State { LOST, FOLLOW, HOME }

var state := State.LOST
## Ziel, zu dem Anaja am Ende läuft (z. B. Mama)
var home_x := 0.0
var _t := 0.0
var _say := ""
var _say_t := 0.0
var _tip := 0
var _tip_t := 6.0
var _moving := false
var _face := -1.0
var _bubble := StyleBoxFlat.new()


func _ready() -> void:
	_bubble.bg_color = Color(1, 1, 1, 0.95)
	_bubble.set_corner_radius_all(16)
	_bubble.border_color = Color("c8641e")
	_bubble.set_border_width_all(3)


func say(text: String, duration := 4.5) -> void:
	_say = text
	_say_t = duration


func go_home(x: float) -> void:
	home_x = x
	state = State.HOME
	Sound.sfx("anaja")
	say("Mama! Da bist du ja!", 5.0)


func _process(delta: float) -> void:
	_t += delta
	_say_t = maxf(_say_t - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_moving = false
	match state:
		State.LOST:
			if player and player.global_position.distance_to(global_position) < MEET_RANGE:
				state = State.FOLLOW
				Sound.sfx("anaja")
				say("Danke, dass du mir hilfst, Brummi! Schau mal – so wirft man Herzen!", 5.0)
				met.emit()
			elif _say_t <= 0.0 and int(_t) % 4 == 0:
				say("Ich hab meine Mama verloren …", 2.0)
		State.FOLLOW:
			if player:
				var side := -signf(player.global_position.x - global_position.x + 0.01)
				var target := player.global_position.x + side * 120.0
				var old_x := global_position.x
				global_position.x = move_toward(global_position.x, target, 420.0 * delta)
				global_position.y = move_toward(global_position.y, player.global_position.y, 700.0 * delta)
				_moving = absf(global_position.x - old_x) > 0.5
				if _moving:
					_face = signf(global_position.x - old_x)
			_tip_t -= delta
			if _tip_t <= 0.0:
				_tip_t = 14.0
				say(TIPS[_tip % TIPS.size()], 5.0)
				_tip += 1
		State.HOME:
			var old_x := global_position.x
			global_position.x = move_toward(global_position.x, home_x, 300.0 * delta)
			_moving = absf(global_position.x - old_x) > 0.5
			if _moving:
				_face = signf(global_position.x - old_x)
	queue_redraw()


func _draw() -> void:
	var tex := TEX_IDLE
	var hop := 0.0
	match state:
		State.LOST:
			tex = TEX_SAD
		State.FOLLOW:
			if _moving:
				tex = TEX_RUN
				hop = -absf(sin(_t * 10.0)) * 10.0
		State.HOME:
			tex = TEX_RUN if _moving else TEX_HAPPY
			if not _moving:
				hop = -absf(sin(_t * 6.0)) * 18.0
	var w := tex.get_width() * HEIGHT / tex.get_height()
	var r := Rect2(-w * 0.5, -HEIGHT + hop + 6.0, w, HEIGHT)
	if _face < 0.0:
		r = Rect2(w * 0.5, r.position.y, -w, HEIGHT)
	draw_texture_rect(tex, r, false)
	if _say_t > 0.0:
		var font := ThemeDB.fallback_font
		var size := 24
		var ts := font.get_multiline_string_size(_say, HORIZONTAL_ALIGNMENT_LEFT, 420.0, size)
		var br := Rect2(Vector2(-ts.x * 0.5 - 16.0, -HEIGHT - 50.0 - ts.y), ts + Vector2(32, 22))
		draw_style_box(_bubble, br)
		draw_multiline_string(font, br.position + Vector2(16, 11 + font.get_ascent(size)), _say, HORIZONTAL_ALIGNMENT_LEFT, 420.0, size, -1, Color("5a2a0a"))
