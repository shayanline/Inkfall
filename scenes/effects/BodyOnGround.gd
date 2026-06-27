class_name BodyOnGround
extends BoardObject
## A prone, near black figure lying on the ground in a pool of blood, ported from the old
## BodyOnGround. Built from ink silhouette shapes over a dark red pool. Appears on the blood flag,
## which the base handles, and the base also mirrors the body when flip is set.


func _ready() -> void:
	add_child(_poly(_ellipse_pts(30.0, 2.0, 34.0, 9.0), Color8(158, 0, 14)))
	add_child(_poly(_ellipse_pts(-6.0, -7.0, 26.0, 9.0), Palette.INK))
	add_child(_poly(_oct_pts(-30.0, -9.0, 8.0), Palette.INK))
	add_child(_poly(_ellipse_pts(-48.0, -3.0, 9.0, 3.0), Palette.INK))
	add_child(_poly(_rect(-52.0, -10.0, 8.0, 6.0), Palette.INK))
	add_child(_poly(_rect(14.0, -11.0, 24.0, 6.0), Palette.INK))
	add_child(_poly(_rect(14.0, -3.0, 22.0, 6.0), Palette.INK))


func _poly(points: PackedVector2Array, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = col
	return p


func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])


func _oct_pts(cx: float, cy: float, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := float(i) / 8.0 * TAU + PI / 8.0
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts


func _ellipse_pts(cx: float, cy: float, rx: float, ry: float, seg: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := float(i) / float(seg) * TAU
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts
