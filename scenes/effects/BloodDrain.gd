class_name BloodDrain
extends BoardObject
## A thin red rivulet that creeps along the ground from the origin toward a drain point, ported from
## the old BloodDrain. After the line set by drain_at it grows along a curved path, tapering as it
## reaches the drain. Appears on the blood flag, which the base handles. drain_x and drain_y are the
## drain offset in design units relative to the origin.

const GROW_DURATION := 5.0

var _streak: Line2D
var _tip: Polygon2D
var _drain_at := 0
var _drain_x := 120.0
var _drain_y := 12.0
var _grow := 0.0
var _path: PackedVector2Array


func on_object_params(p: Dictionary) -> void:
	super.on_object_params(p)
	_drain_at = int(p.get("drain_at", 0))
	_drain_x = float(p.get("drain_x", 120.0))
	_drain_y = float(p.get("drain_y", 12.0))


func _ready() -> void:
	add_child(_poly(_oct_pts(0.0, 0.0, 6.0), Color8(116, 0, 12)))
	var mid := Vector2(_drain_x, _drain_y) * 0.5 + Vector2(0.0, 14.0)
	_path = _quad(Vector2(0.0, 0.0), mid, Vector2(_drain_x, _drain_y), 40)
	_streak = Line2D.new()
	_streak.width = 4.0
	_streak.default_color = Color(0.69, 0.0, 0.063, 0.85)
	_streak.joint_mode = Line2D.LINE_JOINT_ROUND
	_streak.end_cap_mode = Line2D.LINE_CAP_ROUND
	var wc := Curve.new()
	wc.add_point(Vector2(0.0, 1.0))
	wc.add_point(Vector2(1.0, 0.35))
	_streak.width_curve = wc
	add_child(_streak)
	_tip = _poly(_oct_pts(0.0, 0.0, 4.0), Color8(170, 30, 50))
	_tip.visible = false
	add_child(_tip)


func on_tick() -> void:
	if board == null or board.line_index < _drain_at:
		return
	_grow = clampf(_grow + get_process_delta_time() / GROW_DURATION, 0.0, 1.0)
	var count := int(round(_grow * float(_path.size() - 1)))
	var pts := PackedVector2Array()
	for i in count + 1:
		pts.append(_path[i])
	_streak.points = pts
	if pts.size() > 0:
		_tip.position = pts[pts.size() - 1]
		_tip.visible = _grow > 0.8


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


func _quad(p0: Vector2, c: Vector2, p1: Vector2, steps: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var u := float(i) / float(steps)
		var iu := 1.0 - u
		pts.append(iu * iu * p0 + 2.0 * iu * u * c + u * u * p1)
	return pts
