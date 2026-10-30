class_name Platform
extends AnimatableBody2D

enum Kind { GROUND, ISLAND, BRIDGE }

const GROUND_TEX: Array[Texture2D] = [preload("res://assets/terrain/ground1.png"), preload("res://assets/terrain/ground2.png")]
const ISLAND_TEX: Texture2D = preload("res://assets/terrain/island.png")
const BRIDGE_TEX: Texture2D = preload("res://assets/terrain/bridge.png")
const CHUNK_WIDTH := 560.0
const CHUNK_OVERLAP := 200.0

static var _surface_cache := {}

var kind := Kind.GROUND
var size := Vector2(400, 700)
## Verschiebung für bewegliche Inseln (hin und her)
var move := Vector2.ZERO
var ground_tex: Array[Texture2D] = GROUND_TEX
var island_tex: Texture2D = ISLAND_TEX
var bridge_tex: Texture2D = BRIDGE_TEX
var fill_color := Color("3b3528")


# Oberkante der begehbaren Fläche in Texturpixeln: erste Zeile, die über die Bildmitte fast vollständig deckend ist.
static func surface_of(tex: Texture2D) -> float:
	if _surface_cache.has(tex):
		return _surface_cache[tex]
	var img := tex.get_image()
	var x0 := int(img.get_width() * 0.25)
	var x1 := int(img.get_width() * 0.75)
	var result := 0.0
	for y in img.get_height():
		var solid := 0
		for x in range(x0, x1, 2):
			if img.get_pixel(x, y).a > 0.5:
				solid += 1
		if solid >= (x1 - x0) / 2 * 0.6:
			result = y
			break
	_surface_cache[tex] = result
	return result


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	match kind:
		Kind.GROUND:
			shape.size = size
			_build_ground()
		Kind.ISLAND:
			shape.size = Vector2(size.x, 40)
			_add_sprite(island_tex, Vector2(size.x * 0.5, 0), (size.x + 40.0) / island_tex.get_width(), false, -2)
		Kind.BRIDGE:
			shape.size = Vector2(size.x + 40.0, 20)
			cs.one_way_collision = true
			var s := (size.x + 120.0) / bridge_tex.get_width()
			_add_sprite(bridge_tex, Vector2(size.x * 0.5, 4), s, false, -1)
	cs.shape = shape
	cs.position = shape.size * 0.5 - Vector2((shape.size.x - size.x) * 0.5, 0)
	add_child(cs)
	if move != Vector2.ZERO:
		var tw := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		var dur := move.length() / 140.0
		tw.tween_property(self, "position", position + move, dur).set_trans(Tween.TRANS_SINE)
		tw.tween_property(self, "position", position, dur).set_trans(Tween.TRANS_SINE)


func _build_ground() -> void:
	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([Vector2(70, 60), Vector2(size.x - 70, 60), Vector2(size.x - 110, size.y), Vector2(110, size.y)])
	fill.color = fill_color
	fill.z_index = -3
	add_child(fill)
	var step := CHUNK_WIDTH - CHUNK_OVERLAP
	var count := maxi(int(ceil((size.x - CHUNK_OVERLAP) / step)), 1)
	var spread := (size.x + 40.0 - CHUNK_WIDTH) / maxf(count - 1, 1)
	var seed_i := int(position.x / 100.0)
	for i in count:
		var tex := ground_tex[(i + seed_i) % ground_tex.size()]
		var x := -20.0 + CHUNK_WIDTH * 0.5 + spread * i if count > 1 else size.x * 0.5
		var s := CHUNK_WIDTH / tex.get_width()
		if count == 1:
			s = (size.x + 40.0) / tex.get_width()
		_add_sprite(tex, Vector2(x, 0), s, (i + seed_i) % 3 == 1, -2 + (i % 2))


func _add_sprite(tex: Texture2D, top_center: Vector2, s: float, flip: bool, z: int) -> void:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	sp.flip_h = flip
	sp.scale = Vector2(s, s)
	sp.offset = Vector2(-tex.get_width() * 0.5, -surface_of(tex) - 6.0)
	sp.position = top_center
	sp.z_index = z
	add_child(sp)
