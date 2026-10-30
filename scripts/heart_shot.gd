class_name HeartShot
extends Area2D

## Brummis Herz-Wurf: fliegt geradeaus, macht grimmige Wesen wieder lieb.

const TEX: Texture2D = preload("res://assets/items/heart_shot.png")
const SPEED := 1150.0
const LIFE := 0.85
const SIZE := 54.0

var dir := 1
var _t := 0.0
var _done := false


## Kleine Herzchen, die auseinanderfliegen und verblassen.
static func burst(parent: Node, pos: Vector2, count := 6) -> void:
	for i in count:
		var h := Sprite2D.new()
		h.texture = TEX
		var s := randf_range(18.0, 30.0) / TEX.get_height()
		h.scale = Vector2(s, s)
		h.position = pos
		h.z_index = 5
		parent.add_child(h)
		var target := pos + Vector2(randf_range(-90.0, 90.0), randf_range(-150.0, -50.0))
		var tw := h.create_tween().set_parallel()
		tw.tween_property(h, "position", target, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(h, "modulate:a", 0.0, 0.8).set_delay(0.2)
		tw.chain().tween_callback(h.queue_free)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4
	var shape := CircleShape2D.new()
	shape.radius = 26.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _done:
		return
	if body.has_method("take_hit"):
		body.take_hit(dir)
	elif body is Platform and (body as Platform).kind == Platform.Kind.BRIDGE:
		return
	_pop()


func _pop() -> void:
	_done = true
	set_deferred("monitoring", false)
	burst(get_parent(), global_position, 5)
	queue_free()


func _physics_process(delta: float) -> void:
	_t += delta
	position.x += dir * SPEED * delta
	if _t > LIFE:
		_pop()
	queue_redraw()


func _draw() -> void:
	Shapes.glow(self, Vector2.ZERO, 46.0, Color(1.0, 0.45, 0.65, 0.5), 5)
	for i in 3:
		var p := Vector2(-dir * (24.0 + i * 20.0), sin(_t * 30.0 + i) * 5.0)
		Shapes.glow(self, p, 12.0 - i * 3.0, Color(1.0, 0.7, 0.85, 0.6 - i * 0.15), 3)
	var w := TEX.get_width() * SIZE / TEX.get_height()
	draw_set_transform(Vector2(0, sin(_t * 18.0) * 4.0), sin(_t * 12.0) * 0.2, Vector2.ONE * (1.0 + 0.08 * sin(_t * 25.0)))
	draw_texture_rect(TEX, Rect2(-w * 0.5, -SIZE * 0.5, w, SIZE), false)
