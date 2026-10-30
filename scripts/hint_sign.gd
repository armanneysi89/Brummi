class_name HintSign
extends Node2D

const SIGN_TEX: Texture2D = preload("res://assets/objects/sign.png")
const MAX_TEXT_WIDTH := 460.0
const FONT_SIZE := 26

var hint := ""
var tex: Texture2D = SIGN_TEX
var height := 150.0
var flip := false
var range_x := 260.0

var _alpha := 0.0
var _t := 0.0
var _bubble := StyleBoxFlat.new()


func _ready() -> void:
	_bubble.set_corner_radius_all(16)
	_bubble.border_color = Color("6b4528")
	_bubble.set_border_width_all(4)


func _process(delta: float) -> void:
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var near := player != null and absf(player.global_position.x - global_position.x) < range_x
	_alpha = move_toward(_alpha, 1.0 if near else 0.0, delta * 5.0)
	queue_redraw()


func _draw() -> void:
	var HEIGHT := height
	var s := HEIGHT / tex.get_height()
	var w := tex.get_width() * s
	var breathe := 1.0 + sin(_t * 2.0) * 0.012 if tex != SIGN_TEX else 1.0
	var r := Rect2(-w * 0.5, -HEIGHT * breathe + 6.0, w, HEIGHT * breathe)
	if flip:
		r = Rect2(w * 0.5, r.position.y, -w, r.size.y)
	draw_texture_rect(tex, r, false)

	if _alpha > 0.01 and hint != "":
		var font := ThemeDB.fallback_font
		var text_size := font.get_multiline_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, MAX_TEXT_WIDTH, FONT_SIZE)
		var pad := 18.0
		var lift := (1.0 - _alpha) * 12.0
		var rect := Rect2(Vector2(-text_size.x * 0.5 - pad, -HEIGHT - 30.0 - text_size.y - pad * 2.0 + lift), text_size + Vector2(pad * 2.0, pad * 2.0))
		_bubble.bg_color = Color(1.0, 0.97, 0.9, 0.95 * _alpha)
		_bubble.border_color.a = _alpha
		draw_style_box(_bubble, rect)
		draw_multiline_string(
			font,
			Vector2(rect.position.x + pad, rect.position.y + pad + font.get_ascent(FONT_SIZE)),
			hint, HORIZONTAL_ALIGNMENT_LEFT, MAX_TEXT_WIDTH, FONT_SIZE, -1, Color(0.25, 0.15, 0.08, _alpha)
		)
