class_name Story
extends Control

## Bilder-Geschichte für Intro und Outro: Ken-Burns-Fahrt, Schreibmaschinentext, Weiter mit Enter/Leertaste/Klick.

const INTRO := [
	["intro1", "Im Tal der Lichter lebt Brummi, ein kleiner Teddybär mit einem großen Herzen. Am liebsten spielt er mit seinem besten Freund, dem Häschen Pip."],
	["intro2", "Oma Eule passt auf alle Kinder im Tal auf. Sie sagt immer: „Geht niemals mit Fremden mit – auch nicht, wenn sie nett tun oder euch etwas schenken wollen!“"],
	["intro3", "Eines Tages tauchte am Waldrand ein zotteliges Wesen auf: Graupelz. „Na, kleiner Hase? Komm mit, ich habe ganz viele Bonbons für dich! Aber psst – das ist unser Geheimnis!“"],
	["intro4", "Pip vergaß die Regel. Er nahm den Lutscher … und ging mit dem Fremden mit, tief in den Wald hinein."],
	["intro5", "Brummi hatte alles gesehen. Er lief sofort zu Oma Eule und erzählte ihr alles. Das war genau richtig – Geheimnisse, die Angst machen, darf man immer verraten!"],
	["intro6", "Oma Eule gab ihm ihren Mut-Kristall: „Wenn dich jemand locken will, dann ruf ganz laut NEIN! Lauf weg und hol Hilfe.“ Und so machte sich Brummi auf den Weg, um Pip nach Hause zu bringen."],
]
const OUTRO := [
	["outro1", "„NEIN!“ – So laut hatte Graupelz noch nie jemanden rufen hören. Er rannte davon, so schnell er konnte. Pip war frei!"],
	["outro2", "Zurück bei Oma Eule fielen sich alle in die Arme. „Ich gehe nie wieder mit Fremden mit“, versprach Pip. „Und wenn etwas komisch ist, sage ich es dir sofort.“"],
]
const RULES := [
	"Geh nie mit Fremden mit – auch nicht, wenn sie nett tun.",
	"Nimm keine Geschenke oder Süßigkeiten von Fremden an.",
	"Ruf laut NEIN, lauf weg und hol dir Hilfe.",
	"Erzähl es immer einem Erwachsenen, dem du vertraust.",
	"Geheimnisse, die dir Angst machen, darfst du immer weitersagen.",
]
const LEVEL := "res://levels/level_1.tscn"
const CHARS_PER_SEC := 38.0

static var mode := "intro"

var _slides: Array = []
var _index := -1
var _t := 0.0
var _chars := 0.0
var _phase := "slides"
var _fade := 1.0
var _canvas: Control
var _tex: Texture2D
var _prev_tex: Texture2D
var _box := StyleBoxFlat.new()


func _ready() -> void:
	Brummi.ensure_input_actions()
	if "--outro" in OS.get_cmdline_user_args():
		mode = "outro"
	_slides = OUTRO if mode == "outro" else INTRO
	_box.bg_color = Color(0.05, 0.04, 0.1, 0.72)
	_box.set_corner_radius_all(22)
	_box.border_color = Color(1.0, 0.85, 0.5, 0.5)
	_box.set_border_width_all(2)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	_next()


func _next() -> void:
	_index += 1
	if _index >= _slides.size():
		if mode == "intro":
			_phase = "title"
		else:
			_phase = "rules"
		_t = 0.0
		return
	_prev_tex = _tex
	_tex = load("res://assets/story/%s.png" % _slides[_index][0])
	_t = 0.0
	_chars = 0.0


func _input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("advance") or event.is_action_pressed("jump") \
		or (event is InputEventMouseButton and event.pressed)
	if event.is_action_pressed("skip"):
		_finish()
	elif pressed:
		get_viewport().set_input_as_handled()
		match _phase:
			"slides":
				var text: String = _slides[_index][1]
				if _chars < text.length():
					_chars = text.length()
				else:
					_next()
			"title", "rules":
				if _t > 0.6:
					_finish()


func _finish() -> void:
	if mode == "outro":
		mode = "intro"
	get_tree().change_scene_to_file(LEVEL)


func _process(delta: float) -> void:
	_t += delta
	if _phase == "slides":
		_chars += delta * CHARS_PER_SEC
	_canvas.queue_redraw()


func _text(pos: Vector2, text: String, size: int, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	_canvas.draw_string_outline(font, pos, text, align, width, size, 10, Color(0.05, 0.03, 0.1, col.a * 0.85))
	_canvas.draw_string(font, pos, text, align, width, size, col)


func _draw_slide(tex: Texture2D, t: float, alpha: float) -> void:
	var view := _canvas.size
	var zoom := 1.04 + t * 0.012
	var cover := maxf(view.x / tex.get_width(), view.y / tex.get_height()) * zoom
	var size := Vector2(tex.get_width(), tex.get_height()) * cover
	var pan := Vector2(sin(_index * 1.7) * 0.5, 0.3) * minf(t, 12.0) * 6.0
	_canvas.draw_texture_rect(tex, Rect2((view - size) * 0.5 + pan, size), false, Color(1, 1, 1, alpha))


func _on_draw() -> void:
	var view := _canvas.size
	_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color.BLACK)
	if _phase == "slides":
		var fade_in := clampf(_t / 0.8, 0.0, 1.0)
		if _prev_tex and fade_in < 1.0:
			_draw_slide(_prev_tex, 10.0, 1.0)
		_draw_slide(_tex, _t, fade_in)
		var text: String = _slides[_index][1]
		var shown := text.substr(0, int(_chars))
		var font := ThemeDB.fallback_font
		var w := minf(view.x - 160.0, 1500.0)
		var box := Rect2(Vector2((view.x - w) * 0.5 - 40.0, view.y - 250.0), Vector2(w + 80.0, 200.0))
		_canvas.draw_style_box(_box, box)
		_canvas.draw_multiline_string(font, box.position + Vector2(40, 58), shown, HORIZONTAL_ALIGNMENT_LEFT, w, 36, 4, Color(1, 0.97, 0.9))
		if _chars >= text.length():
			var blink := 0.5 + 0.5 * sin(_t * 5.0)
			_text(box.end - Vector2(300, 22), "Enter / Leertaste ▶", 24, Color(1, 0.9, 0.6, blink))
		_text(Vector2(30, 50), "Esc: überspringen", 22, Color(1, 1, 1, 0.6))
	elif _phase == "title":
		_draw_slide(_tex, 10.0 + _t, 1.0)
		_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color(0.05, 0.03, 0.1, minf(_t, 1.0) * 0.55))
		var a := clampf(_t, 0.0, 1.0)
		_text(Vector2(0, view.y * 0.36), "BRUMMI", 150, Color(1.0, 0.85, 0.4, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		_text(Vector2(0, view.y * 0.36 + 80), "Kleine Pfote. Große Reise.", 44, Color(1, 1, 1, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		_text(Vector2(0, view.y * 0.6), "Level 1 – Das Tal der Lichter", 40, Color(1, 0.95, 0.85, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		_text(Vector2(0, view.y * 0.6 + 70), "A/D laufen · Leertaste springen · J schlagen · K sprinten · E laut NEIN rufen", 28, Color(0.85, 0.95, 1, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		_text(Vector2(0, view.y * 0.85), "Enter: Los geht's!", 34, Color(1, 0.9, 0.5, a * (0.6 + 0.4 * sin(_t * 4.0))), view.x, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_draw_slide(_tex, 10.0 + _t, 1.0)
		_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color(0.05, 0.03, 0.1, minf(_t, 1.0) * 0.7))
		var a := clampf(_t, 0.0, 1.0)
		_text(Vector2(0, 170), "Brummis Mut-Regeln", 72, Color(1.0, 0.85, 0.4, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		for i in RULES.size():
			var ra := clampf(_t - 0.5 - i * 0.4, 0.0, 1.0)
			_text(Vector2(view.x * 0.5 - 620, 300 + i * 90), "★  " + RULES[i], 38, Color(1, 1, 1, ra))
		_text(Vector2(0, view.y - 80), "Enter: Nochmal spielen", 32, Color(1, 0.9, 0.5, a * (0.6 + 0.4 * sin(_t * 4.0))), view.x, HORIZONTAL_ALIGNMENT_CENTER)
