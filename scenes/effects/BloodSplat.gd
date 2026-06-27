class_name BloodSplat
extends BoardObject
## A seeded splatter of blood around the origin, ported from the old BloodSplat. A central pool
## ringed by small red blobs placed by a seeded generator, so the same seed always paints the same
## splatter. Appears on the blood flag, which the base handles.

var _seed := 999.0


func on_object_params(p: Dictionary) -> void:
	super.on_object_params(p)
	_seed = float(p.get("seed", 999.0))


func _ready() -> void:
	add_child(_poly(_ellipse_pts(0.0, 0.0, 14.0, 5.0), Palette.RED))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_seed)
	for i in 16:
		var a := rng.randf() * TAU
		var d := 10.0 + rng.randf() * 44.0
		var rr := 1.0 + rng.randf() * 4.0
		add_child(_poly(_oct_pts(cos(a) * d, sin(a) * d * 0.5, rr), Palette.RED))


func _poly(points: PackedVector2Array, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = col
	return p


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
