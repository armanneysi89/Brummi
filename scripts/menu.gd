class_name Menu
extends Control

## Hauptmenü: Level-Auswahl. Nur freigeschaltete Levels dürfen ausgewählt werden.

const BG_TEX: Texture2D = preload("res://assets/story/menu_bg.png")
const CARDS := {
	1: {"tex": preload("res://assets/story/menu_card1.png"), "title": "Level 1 – Das Tal der Lichter", "subtitle": "Bring Pip sicher nach Hause!"},
	2: {"tex": preload("res://assets/story/menu_card2.png"), "title": "Level 2 – Die Abendrot-Küste", "subtitle": "Bring Anaja zum Leuchtturm!"},
}
const CARD_SIZE := Vector2(620, 388)
const CARD_GAP := 130.0

var _canvas: Control
var _selected := 1
var _t := 0.0
var _box := StyleBoxFlat.new()
var _panel := StyleBoxFlat.new()


func _ready() -> void:
	Brummi.ensure_input_actions()
	_box.bg_color = Color(0.05, 0.04, 0.1, 0.72)
	_box.set_corner_radius_all(22)
	_box.border_color = Color(1.0, 0.85, 0.5, 0.5)
	_box.set_border_width_all(2)
	_panel.bg_color = Color(0.05, 0.04, 0.1, 0.78)
	_panel.set_corner_radius_all(16)
	_panel.border_color = Color(1.0, 0.85, 0.5, 0.35)
	_panel.set_border_width_all(2)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	Sound.play_music("story_calm")


func _process(delta: float) -> void:
	_t += delta
	_canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		_move(-1 if event.is_action_pressed("move_left") else 1)
	elif event.is_action_pressed("advance"):
		_start(_selected)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var lvl := _card_at(event.position)
		if lvl > 0:
			_select(lvl)
			_start(lvl)
	elif event is InputEventMouseMotion:
		var lvl := _card_at(event.position)
		if lvl > 0 and lvl != _selected:
			_select(lvl)


## Level unter der Maus, nur wenn es freigeschaltet ist (sonst 0).
func _card_at(pos: Vector2) -> int:
	for lvl in CARDS:
		if Progress.is_unlocked(lvl) and _card_rect(lvl).has_point(pos):
			return lvl
	return 0


func _select(lvl: int) -> void:
	if lvl != _selected and Progress.is_unlocked(lvl):
		_selected = lvl
		Sound.sfx("ui", -4.0, 1.0, 0.0)


## Auswahl nur zwischen freigeschalteten Levels wechseln.
func _move(dir: int) -> void:
	var unlocked_levels: Array = []
	for lvl in CARDS:
		if Progress.is_unlocked(lvl):
			unlocked_levels.append(lvl)
	if unlocked_levels.size() < 2:
		return
	var i := unlocked_levels.find(_selected)
	i = (i + dir + unlocked_levels.size()) % unlocked_levels.size()
	_select(unlocked_levels[i])


func _start(lvl: int) -> void:
	if not Progress.is_unlocked(lvl):
		return
	Sound.sfx("ui", -2.0, 1.0, 0.0)
	Story.chapter = lvl
	Story.mode = "intro"
	get_tree().change_scene_to_file("res://scenes/story.tscn")


func _card_rect(lvl: int) -> Rect2:
	var n := CARDS.size()
	var total := n * CARD_SIZE.x + (n - 1) * CARD_GAP
	var x0 := (size.x - total) * 0.5
	var cx := x0 + (lvl - 1) * (CARD_SIZE.x + CARD_GAP) + CARD_SIZE.x * 0.5
	return Rect2(Vector2(cx - CARD_SIZE.x * 0.5, size.y * 0.62 - CARD_SIZE.y * 0.5), CARD_SIZE)


func _text(pos: Vector2, text: String, size: int, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	_canvas.draw_string_outline(font, pos, text, align, width, size, 10, Color(0.05, 0.03, 0.1, col.a * 0.85))
	_canvas.draw_string(font, pos, text, align, width, size, col)


func _on_draw() -> void:
	var view := _canvas.size
	_draw_bg(view)
	_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color(0.05, 0.03, 0.1, 0.45))
	var a := clampf(_t, 0.0, 1.0)
	_text(Vector2(0, view.y * 0.16), "BRUMMI", 130, Color(1.0, 0.85, 0.4, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Vector2(0, view.y * 0.16 + 70), "Kleine Pfote. Große Reise.", 40, Color(1, 1, 1, a), view.x, HORIZONTAL_ALIGNMENT_CENTER)
	for lvl in CARDS:
		_draw_card(lvl, a)
	_text(Vector2(0, view.y - 46), "A/D: Level wählen · Enter: Los geht's · M: Musik", 26, Color(1, 1, 1, a * 0.6), view.x, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_bg(view: Vector2) -> void:
	var zoom := 1.04 + _t * 0.008
	var cover := maxf(view.x / BG_TEX.get_width(), view.y / BG_TEX.get_height()) * zoom
	var tsize := Vector2(BG_TEX.get_width(), BG_TEX.get_height()) * cover
	var pan := Vector2(sin(_t * 0.1) * 8.0, 0.0)
	_canvas.draw_texture_rect(BG_TEX, Rect2((view - tsize) * 0.5 + pan, tsize), false, Color.WHITE)


func _draw_card(lvl: int, a: float) -> void:
	var card: Dictionary = CARDS[lvl]
	var rect := _card_rect(lvl)
	var sel := lvl == _selected
	var unlocked := Progress.is_unlocked(lvl)
	if sel:
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(1.0, 0.85, 0.4, 0.18)
		glow.set_corner_radius_all(26)
		_canvas.draw_style_box(glow, rect.grow(10))
	var border := StyleBoxFlat.new()
	border.set_corner_radius_all(22)
	border.border_color = Color(1.0, 0.85, 0.4, 0.9 if sel else 0.35)
	border.set_border_width_all(5 if sel else 2)
	_canvas.draw_style_box(border, rect)
	# Kartenbild (cover)
	var tex: Texture2D = card["tex"]
	var cover := maxf(rect.size.x / tex.get_width(), rect.size.y / tex.get_height())
	var tsize := Vector2(tex.get_width(), tex.get_height()) * cover
	var tpos := rect.position + (rect.size - tsize) * 0.5
	var mod := Color(1, 1, 1, a) if unlocked else Color(0.45, 0.45, 0.5, a)
	_canvas.draw_texture_rect(tex, Rect2(tpos, tsize), false, mod)
	# Unteres Panel mit Titel
	var panel := Rect2(rect.position + Vector2(14, rect.size.y - 96), Vector2(rect.size.x - 28, 82))
	_canvas.draw_style_box(_panel, panel)
	var tcol := Color(1.0, 0.9, 0.55, a) if unlocked else Color(0.75, 0.75, 0.8, a)
	_text(panel.position + Vector2(16, 34), card["title"], 26, tcol)
	_text(panel.position + Vector2(16, 68), card["subtitle"], 22, Color(1, 1, 1, a * 0.85) if unlocked else Color(0.7, 0.7, 0.75, a))
	if not unlocked:
		var c := rect.position + rect.size * Vector2(0.5, 0.42)
		_canvas.draw_rect(Rect2(c + Vector2(-30, -6), Vector2(60, 52)), Color(0.1, 0.1, 0.15, a * 0.9))
		_canvas.draw_arc(c + Vector2(0, -6), 22, PI, TAU, 24, Color(0.8, 0.8, 0.85, a), 8)
		_text(c + Vector2(0, 90), "Noch verschlossen", 26, Color(1, 1, 1, a * 0.9), 400, HORIZONTAL_ALIGNMENT_CENTER)
		_text(c + Vector2(0, 124), "Schließe Level 1 ab, um zu starten", 22, Color(1, 1, 1, a * 0.7), 500, HORIZONTAL_ALIGNMENT_CENTER)
	elif sel:
		var blink := 0.6 + 0.4 * sin(_t * 4.0)
		_text(rect.position + Vector2(0, -44), "▶ Enter: Start", 28, Color(1, 0.9, 0.5, a * blink), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
