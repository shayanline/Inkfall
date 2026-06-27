class_name BloodDrain
extends BoardObject
## A thin red rivulet that creeps along the ground from the source toward a drain point. The source
## blob, the streak and its tip are authored in the scene; this script builds the curved path from
## the drain params and grows the streak along it after the line set by drain_at. Appears on the
## blood flag, which the base handles.

const GROW_DURATION := 5.0

@onready var _streak: Line2D = $Streak
@onready var _tip: Polygon2D = $Tip

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
	var mid := Vector2(_drain_x, _drain_y) * 0.5 + Vector2(0.0, 14.0)
	_path = _quad(Vector2(0.0, 0.0), mid, Vector2(_drain_x, _drain_y), 40)


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


func _quad(p0: Vector2, c: Vector2, p1: Vector2, steps: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var u := float(i) / float(steps)
		var iu := 1.0 - u
		pts.append(iu * iu * p0 + 2.0 * iu * u * c + u * u * p1)
	return pts
