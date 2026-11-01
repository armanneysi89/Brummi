class_name TouchControls
extends CanvasLayer

## Bildschirm-Steuerung für Smartphones: Analogstick links, Tasten rechts. Löst dieselben Input-Actions aus wie die Tastatur.
## Auf dem Desktop mit `-- --touch` erzwingbar.

# [Action, Beschriftung, Mitte relativ zur Ecke (x<0: von rechts, y<0: von unten), Radius]
const BUTTONS := [
	["jump", "Sprung", Vector2(-190, -190), 120.0],
	["punch", "Hau!", Vector2(-440, -130), 85.0],
	["dash", "Dash", Vector2(-420, -320), 80.0],
	["shout", "NEIN!", Vector2(-190, -440), 80.0],
	["shoot", "Herz", Vector2(-660, -250), 75.0],
	["restart", "Neu", Vector2(-1, 70), 42.0],
]
const HIT_SCALE := 1.2
const STICK_RADIUS := 130.0
const STICK_DEADZONE := 0.15
const STICK_REST := Vector2(300, -210)
# Anteil der Bildschirmbreite, in dem ein Touch den Stick aufnimmt
const STICK_ZONE_W := 0.4
const WEB_MOBILE_JS := "window.matchMedia('(pointer: coarse)').matches || /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)"

static var _wanted_cache := -1

var player: Brummi

var _canvas: Control
var _fingers := {}
var _held := {}
var _stick_finger := -1
var _stick_origin := Vector2.ZERO
var _stick_knob := Vector2.ZERO


## Web: Browser-Abfrage, da has_feature("mobile") dort immer false ist.
static func wanted() -> bool:
	if _wanted_cache == -1:
		var yes := OS.get_cmdline_user_args().has("--touch")
		if OS.has_feature("web"):
			yes = yes or bool(JavaScriptBridge.eval(WEB_MOBILE_JS, true))
		else:
			yes = yes or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
		_wanted_cache = 1 if yes else 0
	return _wanted_cache == 1


func _ready() -> void:
	layer = 11
	visible = wanted()
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func _exit_tree() -> void:
	for action in _held.keys():
		_set_action(action, false)


func _center(b: Array) -> Vector2:
	var view := _canvas.size
	var off: Vector2 = b[2]
	var x := off.x if off.x >= 0.0 else view.x + off.x
	if off.x == -1.0:
		x = view.x * 0.5
	var y := off.y if off.y >= 0.0 else view.y + off.y
	return Vector2(x, y)


func _is_active(b: Array) -> bool:
	return b[0] != "shoot" or (player != null and player.can_shoot)


func _hit(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	for b in BUTTONS:
		if not _is_active(b):
			continue
		var d := pos.distance_to(_center(b))
		if d <= (b[3] as float) * HIT_SCALE and d < best_d:
			best = b[0]
			best_d = d
	return best


func _in_stick_zone(pos: Vector2) -> bool:
	var view := _canvas.size
	return pos.x < view.x * STICK_ZONE_W and pos.y > view.y * 0.25


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not visible:
			visible = true
		if event.pressed:
			if _stick_finger == -1 and _in_stick_zone(event.position):
				_stick_finger = event.index
				_stick_origin = event.position
				_stick_knob = event.position
				_set_stick(0.0)
			else:
				_assign(event.index, _hit(event.position))
		elif event.index == _stick_finger:
			_stick_finger = -1
			_set_stick(0.0)
		else:
			_assign(event.index, "")
	elif event is InputEventScreenDrag:
		if event.index == _stick_finger:
			var d: Vector2 = (event.position - _stick_origin).limit_length(STICK_RADIUS)
			_stick_knob = _stick_origin + d
			var x := d.x / STICK_RADIUS
			var v := 0.0
			if absf(x) > STICK_DEADZONE:
				v = signf(x) * (absf(x) - STICK_DEADZONE) / (1.0 - STICK_DEADZONE)
			_set_stick(v)
		else:
			_assign(event.index, _hit(event.position))


func _set_stick(v: float) -> void:
	for pair in [["move_left", maxf(-v, 0.0)], ["move_right", maxf(v, 0.0)]]:
		var action: String = pair[0]
		var strength: float = pair[1]
		if strength > 0.0:
			_set_action(action, true, strength)
		elif _held.has(action):
			_set_action(action, false)


func _assign(index: int, action: String) -> void:
	var old: String = _fingers.get(index, "")
	if old == action:
		return
	if action == "":
		_fingers.erase(index)
	else:
		_fingers[index] = action
	if old != "" and not _fingers.values().has(old):
		_set_action(old, false)
	if action != "":
		_set_action(action, true)


func _set_action(action: String, pressed: bool, strength := 1.0) -> void:
	if pressed:
		_held[action] = true
	else:
		_held.erase(action)
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = strength if pressed else 0.0
	Input.parse_input_event(ev)


func _process(_delta: float) -> void:
	if visible:
		_canvas.queue_redraw()


func _on_draw() -> void:
	var font := ThemeDB.fallback_font
	var active := _stick_finger != -1
	var base := _stick_origin if active else Vector2(STICK_REST.x, _canvas.size.y + STICK_REST.y)
	var knob := _stick_knob if active else base
	_canvas.draw_circle(base, STICK_RADIUS, Color(0.05, 0.04, 0.1, 0.5 if active else 0.3))
	_canvas.draw_arc(base, STICK_RADIUS, 0.0, TAU, 48, Color(1.0, 0.85, 0.5, 0.8 if active else 0.45), 4.0, true)
	_canvas.draw_circle(knob, 58.0, Color(1.0, 0.9, 0.6, 0.75 if active else 0.4))
	_canvas.draw_arc(knob, 58.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.8 if active else 0.45), 3.0, true)

	for b in BUTTONS:
		if not _is_active(b):
			continue
		var c := _center(b)
		var r: float = b[3]
		var down := _held.has(b[0])
		_canvas.draw_circle(c, r, Color(0.05, 0.04, 0.1, 0.62 if down else 0.38))
		_canvas.draw_arc(c, r, 0.0, TAU, 48, Color(1.0, 0.85, 0.5, 0.95 if down else 0.55), 4.0, true)
		var col := Color(1, 1, 1, 0.95 if down else 0.7)
		var size := 34 if r > 60.0 else 26
		_canvas.draw_string(font, c + Vector2(-r, size * 0.35), b[1], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, col)
