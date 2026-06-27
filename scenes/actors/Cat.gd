class_name Cat
extends BoardObject
## A small alley cat sitting on the ground, ported from the old Cat. A near black ink silhouette
## with a faint amber eye and a tail that sways. Art is in design units, y=0 at the base and up is
## negative y. The base handles flip, so this script only builds and animates.

var _tail: Line2D
var _t := 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	add_child(_poly(_ellipse_pts(0.0, -5.0, 12.0, 5.0), Palette.INK))
	add_child(_poly(_rect(-11.0, -6.0, 2.5, 6.0), Palette.INK))
	add_child(_poly(_rect(8.0, -6.0, 2.5, 6.0), Palette.INK))
	add_child(_poly(_oct_pts(11.0, -12.0, 4.0), Palette.INK))
	add_child(_poly(PackedVector2Array([Vector2(8, -15), Vector2(9, -20), Vector2(11, -15)]), Palette.INK))
	add_child(_poly(PackedVector2Array([Vector2(11, -15), Vector2(13, -20), Vector2(14, -15)]), Palette.INK))
	_tail = Line2D.new()
	_tail.width = 2.5
	_tail.default_color = Palette.INK
	_tail.joint_mode = Line2D.LINE_JOINT_ROUND
	_tail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_tail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_tail.points = _quad(Vector2(-11, -6), Vector2(-20, -10), Vector2(-16, -18))
	add_child(_tail)
	add_child(_poly(_oct_pts(12.5, -12.0, 1.0), Palette.AMBER))


func on_tick() -> void:
	_t += get_process_delta_time()
	_tail.points = _quad(Vector2(-11, -6), Vector2(-20, -10.0 + sin(_t * 2.0) * 3.0), Vector2(-16, -18))


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


func _quad(p0: Vector2, c: Vector2, p1: Vector2, steps: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var u := float(i) / float(steps)
		var iu := 1.0 - u
		pts.append(iu * iu * p0 + 2.0 * iu * u * c + u * u * p1)
	return pts
