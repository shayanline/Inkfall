class_name Manhole
extends BoardObject
## A cast iron manhole cover seen flat on the wet street, squashed in y so it reads as ground. The
## cover is a radial pattern of concentric grooves and spokes, built once in _ready from code. y
## stays at zero because the cover lies on the ground.

const SQUASH := 0.42
const SEGMENTS := 24

const SHADOW := Color(0.039, 0.047, 0.063, 1)
const RIM := Color(0.133, 0.149, 0.18, 1)
const INNER := Color(0.078, 0.09, 0.11, 1)
const GROOVE := Color(0, 0, 0, 0.55)


func _ready() -> void:
	_add_disc(Vector2(0, 1.5), 32.0, 32.0 * SQUASH, SHADOW)
	_add_disc(Vector2.ZERO, 29.0, 29.0 * SQUASH, RIM)
	_add_disc(Vector2.ZERO, 25.0, 25.0 * SQUASH, INNER)
	var rr := 7.0
	while rr <= 22.0:
		_add_ring(rr)
		rr += 7.0
	for a in 8:
		var c := cos(a * PI / 4.0)
		var sn := sin(a * PI / 4.0) * SQUASH
		_add_spoke(Vector2(c * 5.0, sn * 5.0), Vector2(c * 23.0, sn * 23.0))
	_add_disc(Vector2.ZERO, 3.0, 1.6, Color.BLACK)


func _ellipse_points(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in SEGMENTS:
		var a := float(i) / float(SEGMENTS) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _add_disc(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = _ellipse_points(center, rx, ry)
	p.color = col
	add_child(p)


func _add_ring(r: float) -> void:
	var l := Line2D.new()
	l.points = _ellipse_points(Vector2.ZERO, r, r * SQUASH)
	l.closed = true
	l.width = 1.3
	l.default_color = GROOVE
	add_child(l)


func _add_spoke(a: Vector2, b: Vector2) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([a, b])
	l.width = 1.3
	l.default_color = GROOVE
	add_child(l)
