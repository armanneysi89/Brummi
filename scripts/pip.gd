class_name Pip
extends Node2D

## Brummis Freund. Sitzt im Käfig, bis Graupelz vertrieben ist, und folgt Brummi danach.

const TEX_CAGED: Texture2D = preload("res://assets/characters/pip_caged.png")
const TEX_HAPPY: Texture2D = preload("res://assets/characters/pip_happy.png")

var freed := false
var _t := 0.0
var _say_t := 0.0
var _bubble := StyleBoxFlat.new()


func _ready() -> void:
	_bubble.bg_color = Color(1, 1, 1, 0.95)
	_bubble.set_corner_radius_all(16)


func free_pip() -> void:
	freed = true
	_say_t = 4.0


func _process(delta: float) -> void:
	_t += delta
	_say_t = maxf(_say_t - delta, 0.0)
	if freed:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player:
			var target := player.global_position.x - 110.0 * signf(player.global_position.x - global_position.x + 0.01)
			global_position.x = move_toward(global_position.x, target, 380.0 * delta)
			global_position.y = move_toward(global_position.y, player.global_position.y, 600.0 * delta)
	queue_redraw()


func _draw() -> void:
	var tex := TEX_HAPPY if freed else TEX_CAGED
	var h := 110.0 if freed else 230.0
	var hop := -absf(sin(_t * 7.0)) * 14.0 if freed else 0.0
	var w := tex.get_width() * h / tex.get_height()
	draw_texture_rect(tex, Rect2(-w * 0.5, -h + hop + 6.0, w, h), false)
	var text := "Danke, Brummi! Ich gehe nie wieder mit Fremden mit!" if freed else "Brummi! Hilfe!"
	if _say_t > 0.0 or (not freed and int(_t) % 3 == 0):
		var font := ThemeDB.fallback_font
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		var r := Rect2(Vector2(-ts.x * 0.5 - 16.0, -h - 70.0), ts + Vector2(32, 22))
		draw_style_box(_bubble, r)
		draw_string(font, r.position + Vector2(16, 11 + font.get_ascent(26)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("2a3a55"))
