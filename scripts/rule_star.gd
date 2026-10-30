class_name RuleStar
extends Area2D

## Sammelbare Mut-Regel: zeigt beim Einsammeln die Regel groß an.

signal collected(text: String)

const TEX: Texture2D = preload("res://assets/items/star.png")

var text := ""
var _t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 46.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(func(body: Node2D) -> void:
		if _taken or not body is Brummi:
			return
		_taken = true
		collected.emit(text)
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.4)
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.chain().tween_callback(queue_free))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0, sin(_t * 2.2) * 8.0)
	Shapes.glow(self, c, 80.0 + sin(_t * 3.0) * 8.0, Color(1.0, 0.85, 0.3, 0.45), 6)
	var h := 84.0
	var w := TEX.get_width() * h / TEX.get_height()
	draw_set_transform(c, sin(_t * 1.5) * 0.15)
	draw_texture_rect(TEX, Rect2(-w * 0.5, -h * 0.5, w, h), false)
