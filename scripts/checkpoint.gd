class_name Checkpoint
extends Area2D

const TEX: Texture2D = preload("res://assets/objects/crystal.png")

var active := false
var _t := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90, 200)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -100)
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	_sprite.centered = false
	_sprite.scale = Vector2(0.55, 0.55)
	_sprite.offset = Vector2(-TEX.get_width() * 0.5, -TEX.get_height() + 12.0)
	_sprite.modulate = Color(0.45, 0.5, 0.6)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Brummi and not active:
		active = true
		Sound.sfx("checkpoint")
		body.spawn_point = global_position
		create_tween().tween_property(_sprite, "modulate", Color(1.3, 1.3, 1.4), 0.4)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if active:
		Shapes.glow(self, Vector2(0, -70), 110.0 + sin(_t * 3.0) * 10.0, Color(0.4, 0.85, 1.0, 0.45), 6)
		for i in 6:
			var ph := fmod(_t * 0.5 + i / 6.0, 1.0)
			Shapes.glow(self, Vector2(sin(i * 2.3) * 50.0, -40.0 - ph * 160.0), 10.0, Color(0.6, 0.95, 1.0, 1.0 - ph), 3)
