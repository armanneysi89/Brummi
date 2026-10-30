class_name Coin
extends Area2D

signal collected

const TEX: Texture2D = preload("res://assets/items/coin.png")

var _t := 0.0
var _taken := false
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_t = position.x * 0.013
	var shape := CircleShape2D.new()
	shape.radius = 34.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Brummi:
		return
	_taken = true
	Sound.coin()
	collected.emit()
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position:y", position.y - 70.0, 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	var s := 0.42
	_sprite.scale = Vector2(s * maxf(absf(cos(_t * (12.0 if _taken else 2.5))), 0.12), s)
	_sprite.position.y = sin(_t * 2.5) * 6.0
	queue_redraw()


func _draw() -> void:
	Shapes.glow(self, _sprite.position, 44.0, Color(1.0, 0.85, 0.3, 0.3), 4)
