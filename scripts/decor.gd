class_name Decor
extends Node2D

const PATH := "res://assets/objects/%s.png"
const GLOWS := {
	"mushroom": Color(1.0, 0.6, 0.2, 0.35),
	"glowflower": Color(0.4, 0.75, 1.0, 0.4),
	"crystal": Color(0.4, 0.85, 1.0, 0.4),
	"lantern": Color(1.0, 0.75, 0.3, 0.45),
}
## Glühpunkt als Anteil der Höhe von unten (Standard: Mitte)
const GLOW_AT := {"lantern": 0.78}

var kind := "bush"
var height := 200.0
var flip := false

var _t := 0.0
var _tex: Texture2D


func _ready() -> void:
	_tex = load(PATH % kind)
	set_process(GLOWS.has(kind))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := height / _tex.get_height()
	var w := _tex.get_width() * s
	if GLOWS.has(kind):
		var r := height * (0.75 + 0.05 * sin(_t * 2.0)) if not GLOW_AT.has(kind) else height * (0.3 + 0.03 * sin(_t * 2.0))
		Shapes.glow(self, Vector2(0, -height * GLOW_AT.get(kind, 0.55)), r, GLOWS[kind], 5)
	var rect := Rect2(-w * 0.5, -height + height * 0.04, w, height)
	if flip:
		rect = Rect2(w * 0.5, rect.position.y, -w, height)
	draw_texture_rect(_tex, rect, false)
