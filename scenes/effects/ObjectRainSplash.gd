class_name ObjectRainSplash
extends CPUParticles2D
## Rain catching on an object: soft specks that bounce off its top surfaces (a hat, shoulders, a
## car roof) where the drops land. The emission points are sampled along the object's top
## silhouette (BoardObject.top_silhouette_points), so the spray hugs the real shape instead of
## floating beside a narrow part like a hat. Authored in the object's design units and parented to
## the object, so it scales, walks and hides with whatever it sits on. CPU particles are used so
## the exact silhouette points can be fed as emission points, which the GL Compatibility renderer
## supports everywhere (desktop, mobile, web).

@export var blood := false

## Top silhouette points in the host object's design space. Set by the board before add_child.
var points: PackedVector2Array

const _SPECK_TEX := preload("res://scenes/effects/rain_speck.png")


func _ready() -> void:
	if points.is_empty():
		queue_free()
		return
	texture = _SPECK_TEX
	local_coords = true
	emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	emission_points = points
	# density follows the catch width so a wide car roof gets more spray than a thin shoulder line.
	amount = clampi(int(_span_width() * 0.5), 12, 48)
	lifetime = 0.5
	preprocess = lifetime
	# burst up off the surface, then local gravity drags the spray back down (design units per sec).
	direction = Vector2(0.0, -1.0)
	spread = 42.0
	gravity = Vector2(0.0, 320.0)
	initial_velocity_min = 28.0
	initial_velocity_max = 65.0
	# tiny: the 512px speck scaled to a few design units, then the object scale renders it in pixels.
	scale_amount_min = 0.003
	scale_amount_max = 0.006
	scale_amount_curve = _shrink_curve()
	color_ramp = _fade_ramp()
	if blood:
		color = Color(0.7, 0.05, 0.07, (Palette.RAIN_ALPHA + 0.22) * 0.85)
	else:
		color = Color(0.78, 0.82, 0.88, Palette.RAIN_ALPHA * 0.85)


func _span_width() -> float:
	var lo := INF
	var hi := -INF
	for p in points:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
	return maxf(hi - lo, 1.0)


## Shrinks each speck to nothing over its life so the spray dissolves rather than blinking off.
func _shrink_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 0.0))
	return c


## Pops the alpha in then fades it out, so specks do not appear or vanish abruptly.
func _fade_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.25, Color(1, 1, 1, 1.0))
	g.set_offset(g.get_point_count() - 1, 1.0)
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	return g
