class_name Portal
extends Area2D

signal reached

const TEX: Texture2D = preload("res://assets/objects/portal.png")
const HEIGHT := 420.0

var open := true
var tex: Texture2D = TEX
var height := HEIGHT
## Leuchtpunkt als Anteil der Höhe von unten
var glow_at := 0.5
var _t := 0.0
var _triggered := false


func _ready() -> void:
	z_index = -1
	collision_layer = 0
	collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(140, 240)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -120)
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Brummi and not _triggered and open:
		_triggered = true
		reached.emit()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := height / tex.get_height()
	var w := tex.get_width() * s
	var c := Vector2(0, -height * glow_at)
	var boost := 1.6 if _triggered else (1.0 if open else 0.0)
	if open:
		Shapes.glow(self, c, 240.0 * boost + sin(_t * 2.0) * 12.0, Color(0.35, 0.85, 1.0, 0.35), 7)
	draw_texture_rect(tex, Rect2(-w * 0.5, -height + 10.0, w, height), false, Color.WHITE if open else Color(0.55, 0.55, 0.65))
	if not open:
		return
	Shapes.glow(self, c, (70.0 + sin(_t * 3.0) * 8.0) * boost, Color(0.5, 0.95, 1.0, 0.6), 5)
	for i in 10:
		var ph := fmod(_t * 0.35 + i * 0.1, 1.0)
		var p := c + Vector2.from_angle(i * 2.4 + _t * 0.5) * (40.0 + ph * 120.0)
		Shapes.glow(self, p, 9.0, Color(0.7, 1.0, 1.0, 1.0 - ph), 3)
