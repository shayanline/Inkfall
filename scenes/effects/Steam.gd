class_name Steam
extends BoardObject
## A slow column of steam rising from the ground, ported from the old Steam. Native particles drift
## upward (negative y), soft round and pale grey at low alpha, fading as they climb. The seed param
## offsets the simulation a little so two vents do not pulse in lockstep.

var _seed := 0.0


func on_object_params(p: Dictionary) -> void:
	super.on_object_params(p)
	_seed = float(p.get("seed", 0.0))


func _ready() -> void:
	var ps := GPUParticles2D.new()
	ps.amount = 18
	ps.lifetime = 6.0
	ps.preprocess = 4.0 + _seed
	ps.randomness = 0.5
	ps.texture = _soft_tex(64)
	ps.modulate = Color(0.784, 0.824, 0.882, 0.10)
	ps.process_material = _make_material()
	add_child(ps)
	ps.emitting = true


func _make_material() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(10.0, 2.0, 0.0)
	m.direction = Vector3(0.0, -1.0, 0.0)
	m.spread = 14.0
	m.gravity = Vector3(0.0, -12.0, 0.0)
	m.initial_velocity_min = 8.0
	m.initial_velocity_max = 16.0
	m.scale_min = 0.6
	m.scale_max = 1.6
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	m.color_ramp = ramp
	return m


func _soft_tex(size: int) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t
