class_name Shapes

static func ellipse(c: Vector2, rx: float, ry: float, segments := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func rot_ellipse(c: Vector2, rx: float, ry: float, angle: float, segments := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(angle))
	return pts


static func heart(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 36:
		var t := TAU * float(i) / 36.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y) * s)
	return pts


static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, layers := 5) -> void:
	for i in layers:
		var k := float(i) / float(layers)
		var layer_col := Color(col.r, col.g, col.b, col.a * 1.6 / float(layers))
		ci.draw_colored_polygon(ellipse(c, r * (1.0 - k * 0.75), r * (1.0 - k * 0.75), 24), layer_col)


static func flower(ci: CanvasItem, c: Vector2, r: float, petal: Color, center: Color, rot := 0.0, petals := 6) -> void:
	for i in petals:
		var a := rot + TAU * float(i) / float(petals)
		var pc := c + Vector2.from_angle(a) * r * 0.55
		ci.draw_colored_polygon(rot_ellipse(pc, r * 0.55, r * 0.3, a), petal)
	ci.draw_colored_polygon(ellipse(c, r * 0.3, r * 0.3, 14), center)
