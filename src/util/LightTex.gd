class_name LightTex
extends RefCounted
## Shared light textures for the native 2D lights, built once and reused. A soft radial falloff
## gives a PointLight2D the round, feathered pool the noir look expects.

static var _radial: GradientTexture2D


static func radial() -> GradientTexture2D:
	if _radial == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 256
		t.height = 256
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_radial = t
	return _radial
