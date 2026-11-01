class_name Hud
extends CanvasLayer

const PORTRAIT: Texture2D = preload("res://assets/ui/bear_portrait.png")
const HEART: Texture2D = preload("res://assets/ui/heart.png")
const COIN: Texture2D = preload("res://assets/items/coin.png")
const STAR: Texture2D = preload("res://assets/items/star.png")
const MAP_SIZE := Vector2(300, 110)

var max_hp := 3
var hp := 3
var coins := 0
var total_coins := 0
var stars := 0
var total_stars := 0
var lured := false
var touch := false
var fade := 0.0
# Für die Minikarte: Plattform-Rechtecke, Levelbreite, Spieler- und Zielposition
var map_rects: Array[Rect2] = []
var level_width := 7600.0
var goal_x := 7300.0
var player: Node2D
var title := "LEVEL 1 – Das Tal der Lichter"
var subtitle := "Bring Pip sicher nach Hause!"

var _canvas: Control
var _t := 0.0
var _box := StyleBoxFlat.new()
var _banner := StyleBoxFlat.new()
var _msg_title := ""
var _msg := ""
var _msg_t := 0.0


func show_message(title: String, text: String, duration := 5.0) -> void:
	_msg_title = title
	_msg = text
	_msg_t = duration


func _ready() -> void:
	layer = 10
	_banner.bg_color = Color(0.1, 0.06, 0.2, 0.82)
	_banner.border_color = Color(1.0, 0.85, 0.4, 0.8)
	_banner.set_border_width_all(3)
	_banner.set_corner_radius_all(20)
	_box.bg_color = Color(0.05, 0.08, 0.15, 0.6)
	_box.border_color = Color(1, 1, 1, 0.35)
	_box.set_border_width_all(2)
	_box.set_corner_radius_all(14)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func _process(delta: float) -> void:
	_t += delta
	_msg_t = maxf(_msg_t - delta, 0.0)
	_canvas.queue_redraw()


func _text(pos: Vector2, text: String, size: int, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	_canvas.draw_string_outline(font, pos, text, align, width, size, 8, Color(0.05, 0.03, 0.1, col.a * 0.8))
	_canvas.draw_string(font, pos, text, align, width, size, col)


func _icon(tex: Texture2D, center: Vector2, h: float, mod := Color.WHITE) -> void:
	var w := tex.get_width() * h / tex.get_height()
	_canvas.draw_texture_rect(tex, Rect2(center - Vector2(w, h) * 0.5, Vector2(w, h)), false, mod)


func _on_draw() -> void:
	var view := _canvas.size

	var pc := Vector2(86, 86)
	_canvas.draw_circle(pc, 66.0, Color("6b4528"))
	_canvas.draw_circle(pc, 60.0, Color(0.55, 0.78, 0.95))
	_icon(PORTRAIT, pc + Vector2(0, 4), 112.0)
	_canvas.draw_arc(pc, 63.0, 0.0, TAU, 48, Color("f1c56a"), 5.0, true)

	for i in max_hp:
		var full := i < hp
		var pulse := 1.0 + (0.08 * sin(_t * 5.0) if full and hp == 1 else 0.0)
		_icon(HEART, Vector2(194.0 + i * 58.0, 62.0), 50.0 * pulse, Color.WHITE if full else Color(0.25, 0.2, 0.25, 0.7))
	_icon(COIN, Vector2(192.0, 122.0), 44.0)
	_text(Vector2(222.0, 136.0), "%d" % coins, 40, Color.WHITE)
	_icon(STAR, Vector2(310.0, 122.0), 46.0)
	_text(Vector2(340.0, 136.0), "%d / %d" % [stars, total_stars], 40, Color(1.0, 0.9, 0.5))

	_draw_minimap(Rect2(view.x - MAP_SIZE.x - 30.0, 30.0, MAP_SIZE.x, MAP_SIZE.y))

	if _t < 6.0:
		var a := clampf(minf(_t * 1.5, (6.0 - _t) * 1.5), 0.0, 1.0)
		_text(Vector2(40.0, view.y - 110.0), title, 52, Color(1, 1, 1, a))
		_text(Vector2(40.0, view.y - 60.0), subtitle, 30, Color(1.0, 0.95, 0.85, a))

	if lured:
		var p := 0.75 + 0.25 * sin(_t * 8.0)
		_canvas.draw_rect(Rect2(Vector2(view.x * 0.5 - 620.0, view.y * 0.8 - 62.0), Vector2(1240.0, 84.0)), Color(0.1, 0.06, 0.15, 0.6 * p))
		_text(Vector2(0, view.y * 0.8), "Nicht mitgehen!  Tipp auf  NEIN!" if touch else "Nicht mitgehen!  Drück  E  und ruf laut NEIN!", 54, Color(1.0, 0.85, 0.3, p), view.x, HORIZONTAL_ALIGNMENT_CENTER)

	if _msg_t > 0.0:
		var a := clampf(minf(_msg_t, 0.4) / 0.4, 0.0, 1.0)
		var font := ThemeDB.fallback_font
		var w := 1100.0
		var th := font.get_multiline_string_size(_msg, HORIZONTAL_ALIGNMENT_CENTER, w, 34).y
		var r := Rect2(Vector2((view.x - w) * 0.5 - 40.0, 170.0), Vector2(w + 80.0, th + 110.0))
		_banner.bg_color.a = 0.82 * a
		_banner.border_color.a = 0.8 * a
		_canvas.draw_style_box(_banner, r)
		_icon(STAR, r.position + Vector2(r.size.x * 0.5, 0), 70.0, Color(1, 1, 1, a))
		_text(Vector2(r.position.x, r.position.y + 68.0), _msg_title, 38, Color(1.0, 0.85, 0.4, a), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_canvas.draw_multiline_string(font, Vector2(r.position.x + 40.0, r.position.y + 112.0), _msg, HORIZONTAL_ALIGNMENT_CENTER, w, 34, -1, Color(1, 1, 1, a))

	if fade > 0.0:
		_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, fade))


func _draw_minimap(r: Rect2) -> void:
	_canvas.draw_style_box(_box, r)
	var inner := r.grow(-14.0)
	var sx := inner.size.x / level_width
	var to_map := func(p: Vector2) -> Vector2:
		return inner.position + Vector2(p.x * sx, (p.y - 300.0) / 700.0 * inner.size.y)
	for pr in map_rects:
		var a: Vector2 = to_map.call(pr.position)
		_canvas.draw_rect(Rect2(a, Vector2(maxf(pr.size.x * sx, 3.0), inner.end.y - a.y)), Color(0.45, 0.75, 0.7, 0.55))
		_canvas.draw_line(a, a + Vector2(pr.size.x * sx, 0), Color(0.7, 1.0, 0.6, 0.9), 2.0)
	var g: Vector2 = to_map.call(Vector2(goal_x, 740))
	_canvas.draw_line(g, g + Vector2(0, -22), Color.WHITE, 2.0)
	_canvas.draw_colored_polygon(PackedVector2Array([g + Vector2(0, -22), g + Vector2(14, -17), g + Vector2(0, -12)]), Color("ffd23f"))
	if player:
		var p: Vector2 = to_map.call(player.global_position)
		p.y = clampf(p.y, inner.position.y, inner.end.y)
		_icon(PORTRAIT, p + Vector2(0, -12), 28.0)
