class_name Background
extends Node2D

const SKY: Texture2D = preload("res://assets/background/bg_sky.png")
const ISLANDS: Array[Texture2D] = [preload("res://assets/background/bg_island1.png"), preload("res://assets/background/bg_island2.png")]
const VIEW := Vector2(1920, 1080)

var level_width := 7600.0
var camera_bottom := 1200.0
var sky: Texture2D = SKY
var props: Array[Texture2D] = ISLANDS
## Höhenbereich und Größe der Hintergrund-Objekte (Inseln, Boote ...)
var prop_y := Vector2(160.0, 480.0)
var prop_scale := Vector2(0.28, 0.5)
var mist_color := Color(0.85, 0.93, 1.0, 0.95)
var fly_color := Color(1.0, 0.92, 0.5)


class _Fireflies extends Node2D:
	var x1 := 0.0
	var color := Color(1.0, 0.92, 0.5)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 37
		for i in 70:
			var fx := rng.randf() * x1
			var fy := rng.randf_range(200.0, 850.0)
			var ph := rng.randf() * TAU
			var p := Vector2(fx + sin(_t * 0.7 + ph) * 30.0, fy + cos(_t * 0.5 + ph) * 20.0)
			Shapes.glow(self, p, 9.0, Color(color, 0.5 + 0.5 * sin(_t * 2.0 + ph)), 3)


func _ready() -> void:
	var cam_range := Vector2(level_width - VIEW.x, camera_bottom - VIEW.y)

	var sky_scale := (VIEW.y + 200.0) / sky.get_height()
	var sky_w := sky.get_width() * sky_scale
	var sky_sprite := Sprite2D.new()
	sky_sprite.texture = sky
	sky_sprite.centered = false
	sky_sprite.scale = Vector2(sky_scale, sky_scale)
	_add_layer(sky_sprite, Vector2((sky_w - VIEW.x) / cam_range.x, 0.5), -30)

	var islands := Node2D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var x := 200.0
	var mid_scroll := 0.3
	while x < level_width * mid_scroll + VIEW.x:
		var sp := Sprite2D.new()
		sp.texture = props[rng.randi() % props.size()]
		var s := rng.randf_range(prop_scale.x, prop_scale.y)
		sp.scale = Vector2(s, s)
		sp.flip_h = rng.randf() < 0.5
		sp.position = Vector2(x, rng.randf_range(prop_y.x, prop_y.y))
		sp.modulate = Color(0.85, 0.9, 1.0, 0.85)
		islands.add_child(sp)
		var bob := sp.create_tween().set_loops()
		bob.tween_property(sp, "position:y", sp.position.y - 14.0, rng.randf_range(2.5, 4.0)).set_trans(Tween.TRANS_SINE)
		bob.tween_property(sp, "position:y", sp.position.y, rng.randf_range(2.5, 4.0)).set_trans(Tween.TRANS_SINE)
		x += rng.randf_range(500.0, 900.0)
	_add_layer(islands, Vector2(mid_scroll, 0.3), -20)

	var mist := Polygon2D.new()
	mist.polygon = PackedVector2Array([Vector2(-200, 880), Vector2(level_width + 200, 880), Vector2(level_width + 200, 1500), Vector2(-200, 1500)])
	mist.vertex_colors = PackedColorArray([Color(mist_color, 0), Color(mist_color, 0), mist_color, mist_color])
	mist.z_index = -5
	add_child(mist)

	var flies := _Fireflies.new()
	flies.x1 = level_width
	flies.color = fly_color
	flies.z_index = 3
	add_child(flies)


func _add_layer(content: Node2D, scroll: Vector2, z: int) -> void:
	var p := Parallax2D.new()
	p.scroll_scale = scroll
	p.z_index = z
	p.add_child(content)
	add_child(p)
