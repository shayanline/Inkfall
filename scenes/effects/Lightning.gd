class_name Lightning
extends Node2D
## Lightning on the weather layer: a full screen flash and an occasional procedural bolt. It can
## be triggered by an fx event (strike) and also fires by itself now and then on an open sky.

@export var self_trigger := true

var _flash: ColorRect
var _bolt: Line2D
var _rng := RandomNumberGenerator.new()
var _next := 5.0


func _ready() -> void:
	var vp := get_viewport_rect().size
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = vp
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_bolt = Line2D.new()
	_bolt.width = 2.5
	_bolt.default_color = Color(1, 1, 1, 0)
	_bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_bolt)


func _process(delta: float) -> void:
	if not self_trigger:
		return
	_next -= delta
	if _next <= 0.0:
		strike()
		_next = _rng.randf_range(6.0, 14.0)


func strike() -> void:
	var vp := get_viewport_rect().size
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.5, 0.05)
	tw.tween_property(_flash, "color:a", 0.0, 0.35)

	if _rng.randf() < 0.8:
		_draw_bolt(vp)


func _draw_bolt(vp: Vector2) -> void:
	var pts := PackedVector2Array()
	var x := vp.x * _rng.randf_range(0.2, 0.8)
	var y := 0.0
	var segs := 9 + _rng.randi_range(0, 5)
	for i in segs + 1:
		pts.append(Vector2(x, y))
		x += _rng.randf_range(-35.0, 35.0)
		y += vp.y * 0.55 / float(segs)
	_bolt.points = pts
	_bolt.default_color = Color(1, 1, 1, 0.95)
	var tw := create_tween()
	tw.tween_property(_bolt, "default_color:a", 0.0, 0.45)
