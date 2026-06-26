class_name FXUtil
extends RefCounted
## Procedural textures and helpers so the look runs with zero image assets. Acquired art
## drops in later, this just makes the native lighting/weather work out of the box.


static func radial_light_texture(size := 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 0.35),
		Color(1, 1, 1, 0),
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


static func streak_texture(w := 3, h := 28) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var a := 1.0 - absf((float(y) / float(h - 1)) - 0.5) * 1.4
		a = clampf(a, 0.0, 1.0)
		for x in w:
			var ax := 1.0 - absf((float(x) / float(w - 1)) - 0.5) * 2.0
			img.set_pixel(x, y, Color(1, 1, 1, a * clampf(ax, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func soft_dot_texture(size := 64) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
