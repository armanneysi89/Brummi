class_name Story
extends Control

## Bilder-Geschichte für Intro und Outro: Ken-Burns-Fahrt, Schreibmaschinentext, Weiter mit Enter/Leertaste/Klick.

const INTRO_1 := [
	["intro1", "Im Tal der Lichter lebt Brummi, ein kleiner Teddybär mit einem großen Herzen. Am liebsten spielt er mit seinem besten Freund, dem Häschen Pip."],
	["intro2", "Oma Eule passt auf alle Kinder im Tal auf. Sie sagt immer: „Geht niemals mit Fremden mit – auch nicht, wenn sie nett tun oder euch etwas schenken wollen!“"],
	["intro3", "Eines Tages tauchte am Waldrand ein zotteliges Wesen auf: Graupelz. „Na, kleiner Hase? Komm mit, ich habe ganz viele Bonbons für dich! Aber psst – das ist unser Geheimnis!“"],
	["intro4", "Pip vergaß die Regel. Er nahm den Lutscher … und ging mit dem Fremden mit, tief in den Wald hinein."],
	["intro5", "Brummi hatte alles gesehen. Er lief sofort zu Oma Eule und erzählte ihr alles. Das war genau richtig – Geheimnisse, die Angst machen, darf man immer verraten!"],
	["intro6", "Oma Eule gab ihm ihren Mut-Kristall: „Wenn dich jemand locken will, dann ruf ganz laut NEIN! Lauf weg und hol Hilfe.“ Und so machte sich Brummi auf den Weg, um Pip nach Hause zu bringen."],
]
const OUTRO_1 := [
	["outro1", "„NEIN!“ – So laut hatte Graupelz noch nie jemanden rufen hören. Er rannte davon, so schnell er konnte. Pip war frei!"],
	["outro2", "Zurück bei Oma Eule fielen sich alle in die Arme. „Ich gehe nie wieder mit Fremden mit“, versprach Pip. „Und wenn etwas komisch ist, sage ich es dir sofort.“"],
]
const RULES_1 := [
	"Geh nie mit Fremden mit – auch nicht, wenn sie nett tun.",
	"Nimm keine Geschenke oder Süßigkeiten von Fremden an.",
	"Ruf laut NEIN, lauf weg und hol dir Hilfe.",
	"Erzähl es immer einem Erwachsenen, dem du vertraust.",
	"Geheimnisse, die dir Angst machen, darfst du immer weitersagen.",
]
const INTRO_2 := [
	["l2_intro1", "Ein paar Tage später fuhren Brummi und Pip zum großen Laternenfest an der Abendrot-Küste. Überall leuchteten Lampions, und das Meer glitzerte golden."],
	["l2_intro2", "Auf dem Steg stand ein kleines Fuchsmädchen ganz allein und weinte. „Ich bin Anaja“, schluchzte sie. „Ich habe meine Mama im Gedränge verloren!“"],
	["l2_intro3", "Brummi setzte sich zu ihr. „Habt ihr einen Treffpunkt ausgemacht?“ Anaja nickte und zeigte auf den Leuchtturm: „Wenn wir uns verlieren, treffen wir uns dort!“"],
	["l2_intro4", "Plötzlich stand da jemand mit einer Matrosenmütze. „Deine Mama schickt mich, Kleine! Komm mit, ich bring dich zu ihr!“ Aber Brummi erkannte die zotteligen Ohren: Das war Graupelz!"],
	["l2_intro5", "„NEIN!“, riefen beide. Graupelz rannte davon und rief seine Robo-Krabben und Robo-Möwen. Da zeigte Anaja Brummi ihren Zauber: „Mit Herzen werden grimmige Wesen wieder lieb!“"],
	["l2_intro6", "Pip lief zu den Hafenleuten, um Bescheid zu sagen. Und Brummi und Anaja machten sich gemeinsam auf den Weg zum Leuchtturm."],
]
const OUTRO_2 := [
	["l2_outro1", "Am Leuchtturm wartete Graupelz ein letztes Mal. Doch gegen ein lautes NEIN und eine Ladung Herzen hatte er keine Chance – und weg war er!"],
	["l2_outro2", "„ANAJA!“ Mama Fuchs schloss ihre Tochter fest in die Arme. „Ihr habt alles richtig gemacht“, sagte sie zu Brummi. „Am Treffpunkt warten – das war sehr klug!“"],
]
const RULES_2 := [
	"Verlaufen? Bleib stehen und lauf nicht kreuz und quer.",
	"Macht vorher einen Treffpunkt aus.",
	"Hol Hilfe bei jemandem, der dort arbeitet – oder bei einer Mama mit Kindern.",
	"Lerne deinen Namen, deine Adresse und eine Telefonnummer.",
	"„Deine Mama schickt mich“? Geh trotzdem nie mit Fremden mit!",
]
const CHAPTERS := {
	1: {"intro": INTRO_1, "outro": OUTRO_1, "rules": RULES_1, "level": "res://levels/level_1.tscn", "title": "Level 1 – Das Tal der Lichter"},
	2: {"intro": INTRO_2, "outro": OUTRO_2, "rules": RULES_2, "level": "res://levels/level_2.tscn", "title": "Level 2 – Die Abendrot-Küste"},
}
const CHARS_PER_SEC := 38.0
const MOODS := {
	"intro1": "story_calm", "intro2": "story_calm", "intro3": "story_dark", "intro4": "story_dark",
	"intro5": "story_hope", "intro6": "story_hope", "outro1": "story_hope", "outro2": "story_calm",
	"l2_intro1": "story_calm", "l2_intro2": "story_calm", "l2_intro3": "story_calm", "l2_intro4": "story_dark",
	"l2_intro5": "story_hope", "l2_intro6": "story_hope", "l2_outro1": "story_hope", "l2_outro2": "story_calm",
}

static var mode := "intro"
static var chapter := 1
static var _args_read := false

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
	for arg in OS.get_cmdline_user_args() if not _args_read else []:
		if arg == "--outro":
			mode = "outro"
		elif arg.begins_with("--chapter="):
			chapter = clampi(arg.trim_prefix("--chapter=").to_int(), 1, CHAPTERS.size())
	_args_read = true
	_slides = CHAPTERS[chapter][mode]
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
	Sound.play_music(MOODS[_slides[_index][0]], 2.0)
	_t = 0.0
	_chars = 0.0


func _input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("advance") or event.is_action_pressed("jump") \
		or (event is InputEventMouseButton and event.pressed)
	if event.is_action_pressed("skip"):
		_finish()
	elif pressed:
		get_viewport().set_input_as_handled()
		Sound.sfx("ui", -4.0, 1.0, 0.0)
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
		# Nach dem Outro zurück ins Hauptmenü
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	get_tree().change_scene_to_file(CHAPTERS[chapter]["level"])


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
		_text(Vector2(0, view.y * 0.6), CHAPTERS[chapter]["title"], 40, Color(1, 0.95, 0.85, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		var keys := "A/D laufen · Leertaste springen · J schlagen · K sprinten · E laut NEIN rufen"
		if chapter >= 2:
			keys += " · L Herz werfen"
		_text(Vector2(0, view.y * 0.6 + 70), keys, 28, Color(0.85, 0.95, 1, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		_text(Vector2(0, view.y * 0.85), "Enter: Los geht's!", 34, Color(1, 0.9, 0.5, a * (0.6 + 0.4 * sin(_t * 4.0))), view.x, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_draw_slide(_tex, 10.0 + _t, 1.0)
		_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color(0.05, 0.03, 0.1, minf(_t, 1.0) * 0.7))
		var a := clampf(_t, 0.0, 1.0)
		var rules: Array = CHAPTERS[chapter]["rules"]
		_text(Vector2(0, 170), "Brummis Mut-Regeln", 72, Color(1.0, 0.85, 0.4, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
		for i in rules.size():
			var ra := clampf(_t - 0.5 - i * 0.4, 0.0, 1.0)
			_text(Vector2(view.x * 0.5 - 620, 300 + i * 90), "★  " + rules[i], 38, Color(1, 1, 1, ra))
		var next := "Enter: Weiter zu Level %d" % (chapter + 1) if CHAPTERS.has(chapter + 1) else "Enter: Nochmal spielen"
		_text(Vector2(0, view.y - 80), next, 32, Color(1, 0.9, 0.5, a * (0.6 + 0.4 * sin(_t * 4.0))), view.x, HORIZONTAL_ALIGNMENT_CENTER)
