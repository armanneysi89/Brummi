class_name Decor
extends Node2D

const TEXTURES := {
	"tree": preload("res://assets/objects/tree.png"),
	"bush": preload("res://assets/objects/bush.png"),
	"mushroom": preload("res://assets/objects/mushroom.png"),
	"glowflower": preload("res://assets/objects/glowflower.png"),
	"crystal": preload("res://assets/objects/crystal.png"),
	"crate": preload("res://assets/objects/crate.png"),
}
const GLOWS := {
	"mushroom": Color(1.0, 0.6, 0.2, 0.35),
	"glowflower": Color(0.4, 0.75, 1.0, 0.4),
	"crystal": Color(0.4, 0.85, 1.0, 0.4),
}

var kind := "bush"
var height := 200.0
var flip := false

var _t := 0.0
var _tex: Texture2D


func _ready() -> void:
	_tex = TEXTURES[kind]
	set_process(GLOWS.has(kind))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := height / _tex.get_height()
	var w := _tex.get_width() * s
	if GLOWS.has(kind):
		Shapes.glow(self, Vector2(0, -height * 0.55), height * (0.75 + 0.05 * sin(_t * 2.0)), GLOWS[kind], 5)
	var rect := Rect2(-w * 0.5, -height + height * 0.04, w, height)
	if flip:
		rect = Rect2(w * 0.5, rect.position.y, -w, height)
	draw_texture_rect(_tex, rect, false)
