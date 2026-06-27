class_name Crow
extends BoardObject
## A perched crow that flaps and flies off, ported from the old Crow. It sits still until the line
## set by fly_at, then beats its wings and lifts away across the frame, fading out. Art is in design
## units, x centred on 0, with no scale premultiply.

const FLY_DURATION := 4.0

var _art: Node2D
var _tail: Polygon2D
var _wing: Polygon2D
var _leg: Polygon2D
var _t := 0.0
var _fly := 0.0
var _fly_active := false
var _fly_at = null
var _delay := 0.0


func on_object_params(p: Dictionary) -> void:
	super.on_object_params(p)
	_fly_at = int(p["fly_at"]) if p.has("fly_at") else null
	_delay = float(p.get("delay", 0.0))


func _ready() -> void:
	_art = Node2D.new()
	_art.scale = Vector2(-1.0, 1.0)
	add_child(_art)
	_build()


func _build() -> void:
	_art.add_child(_poly(_ellipse_pts(0.0, 0.0, 7.0, 4.0), Palette.INK))
	_art.add_child(_poly(_oct_pts(-6.0, -3.0, 3.0), Palette.INK))
	_art.add_child(_poly(_rect(-10.0, -3.0, 4.0, 1.4), Palette.INK))
	_tail = _poly(PackedVector2Array(), Palette.INK)
	_wing = _poly(PackedVector2Array(), Palette.INK)
	_leg = _poly(_rect(1.0, 4.0, 1.4, 5.0), Palette.INK)
	_art.add_child(_tail)
	_art.add_child(_wing)
	_art.add_child(_leg)
	_shape(false, 0.5, 0.0)


func on_line(idx: int) -> void:
	super.on_line(idx)
	if _fly_at != null and idx >= int(_fly_at):
		_fly_active = true


func on_tick() -> void:
	var dt := get_process_delta_time()
	_t += dt
	if _fly_active and _delay > 0.0:
		_delay = maxf(0.0, _delay - dt)
	elif _fly_active:
		_fly = clampf(_fly + dt / FLY_DURATION, 0.0, 1.0)
	var flying := _fly > 0.02
	var w := sin(_t * (2.4 if flying else 1.0)) * 0.5 + 0.5
	var wob := sin(_t * 1.6) * 2.2
	_shape(flying, w, wob)
	var vp := get_viewport_rect().size
	_art.position = Vector2(_fly * vp.x * 0.5, -_fly * vp.y * 0.6)
	modulate.a = 1.0 - _fly
	_leg.visible = not flying
	if _fly >= 0.99:
		visible = false


func _shape(flying: bool, w: float, wob: float) -> void:
	var wt := -2.0 - (13.0 if flying else 4.0) * w
	var tl := _quad(Vector2(5, -1), Vector2(11, 1.0 + wob), Vector2(14, 2.0 + wob), 10)
	tl.append(Vector2(5, 2))
	_tail.polygon = tl
	var wg := _quad(Vector2(2, -1), Vector2(8, wt * 0.6), Vector2(13, wt), 10)
	var wg2 := _quad(Vector2(13, wt), Vector2(8, 1), Vector2(3, 1.5), 10)
	for i in range(1, wg2.size()):
		wg.append(wg2[i])
	_wing.polygon = wg


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


func _ellipse_pts(cx: float, cy: float, rx: float, ry: float, seg: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := float(i) / float(seg) * TAU
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts


func _quad(p0: Vector2, c: Vector2, p1: Vector2, steps: int = 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var u := float(i) / float(steps)
		var iu := 1.0 - u
		pts.append(iu * iu * p0 + 2.0 * iu * u * c + u * u * p1)
	return pts
